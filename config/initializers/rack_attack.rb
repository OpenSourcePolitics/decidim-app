# frozen_string_literal: true

require 'decidim-app/rack_attack'

# Source: https://github.com/rack/rack-attack/issues/145#issuecomment-886180424
class Rack::Attack
  class Request < ::Rack::Request
    def remote_ip
      # doc: https://api.rubyonrails.org/classes/ActionDispatch/RemoteIp.html
      @remote_ip ||= ActionDispatch::Request.new(env).remote_ip
    end
  end
end

# Enabled by default in production
# Can be deactivated with 'ENABLE_RACK_ATTACK=0'
Rack::Attack.enabled = DecidimApp::RackAttack.rack_enabled?
return unless Rack::Attack.enabled

# Remove the original throttle from decidim-core
# see https://github.com/decidim/decidim/blob/release/0.26-stable/decidim-core/config/initializers/rack_attack.rb#L19
DecidimApp::RackAttack.deactivate_decidim_throttling!

Rack::Attack.throttled_response_retry_after_header = true
# By default use the memory store for inspecting requests
# Better to use MemCached or Redis in production mode
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if !ENV["MEMCACHEDCLOUD_SERVERS"] || Rails.env.test?

Rack::Attack.throttled_responder = lambda do |request|
  rack_logger = Logger.new(Rails.root.join("log/rack_attack.log"))
  throttling_limit = DecidimApp::RackAttack.throttling_limit_for(request.env["rack.attack.match_data"])

  request_uuid = request.env["action_dispatch.request_id"]
  params = {
    "ip" => request.remote_ip,
    "path" => request.path,
    "get" => request.GET,
    "host" => request.host,
    "referer" => request.referer
  }

  rack_logger.warn("[#{request_uuid}] #{params}")

  [429, { "Content-Type" => "text/html" }, [DecidimApp::RackAttack.html_template(throttling_limit, request.env["decidim.current_organization"]&.name)]]
end

Rack::Attack.throttle("req/ip",
                      limit: Rails.application.secrets.dig(:decidim, :rack_attack, :throttle, :max_requests),
                      period: Rails.application.secrets.dig(:decidim, :rack_attack, :throttle, :period)) do |req|

  req.remote_ip unless DecidimApp::RackAttack.authorized_throttle_path?(req.path)
end

if Rails.application.secrets.dig(:decidim, :rack_attack, :fail2ban, :enabled) == 1
  # Block suspicious requests made for pentesting
  # After 1 forbidden request, block all requests from that IP for 1 hour.
  Rack::Attack.blocklist("fail2ban pentesters") do |req|
    # `filter` returns truthy value if request fails, or if it's from a previously banned IP
    # so the request is blocked
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.remote_ip}", maxretry: 0, findtime: 10.minutes, bantime: 1.hour) do
      # The count for the IP is incremented if the return value is truthy
      DecidimApp::RackAttack.unauthorized_fail2ban_path?(req.path)
    end
  end
end

