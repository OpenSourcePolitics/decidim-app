# frozen_string_literal: true

module DecidimApp
  module RackAttack
    def self.rack_enabled?
      setting = Rails.application.secrets.dig(:decidim, :rack_attack, :enabled)
      return setting == "1" if setting.present?

      Rails.env.production?
    end

    def self.apply_configuration
      Rack::Attack.enabled = true

      # Remove the original throttle from decidim-core
      # see https://github.com/decidim/decidim/blob/release/0.26-stable/decidim-core/config/initializers/rack_attack.rb#L19
      DecidimApp::RackAttack::Throttling.deactivate_decidim_throttling! do
        Rails.logger.info("Deactivating 'requests by ip' from Decidim Core")
        Rack::Attack.throttles.delete("requests by ip")
      end

      Rack::Attack.throttled_response_retry_after_header = true

      Rack::Attack.throttled_responder = lambda do |request|
        rack_logger = Logger.new(Rails.root.join("log/rack_attack.log"))
        throttling_limit = DecidimApp::RackAttack::Throttling.time_limit_for(request.env["rack.attack.match_data"])

        request_uuid = request.env["action_dispatch.request_id"]
        params = {
          "ip" => request.ip,
          "path" => request.path,
          "get" => request.GET,
          "host" => request.host,
          "referer" => request.referer
        }

        rack_logger.warn("[#{request_uuid}] #{params}")

        [429, { "Content-Type" => "text/html" }, [DecidimApp::RackAttack::Throttling.html_template(throttling_limit, request.env["decidim.current_organization"]&.name)]]
      end

      Rack::Attack.throttle(DecidimApp::RackAttack::Throttling.name,
                            limit: DecidimApp::RackAttack::Throttling.max_requests,
                            period: DecidimApp::RackAttack::Throttling.period) do |req|
        req.ip unless DecidimApp::RackAttack::Throttling.authorized_path?(req.path)
      end

      return unless DecidimApp::RackAttack::Fail2ban.enabled?

      # Block suspicious requests made for pentesting
      # After 1 forbidden request, block all requests from that IP for 1 hour.
      Rack::Attack.blocklist("fail2ban pentesters") do |req|
        # `filter` returns truthy value if request fails, or if it's from a previously banned IP
        # so the request is blocked
        Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 0, findtime: 10.minutes, bantime: 1.hour) do
          # The count for the IP is incremented if the return value is truthy
          DecidimApp::RackAttack::Fail2ban.unauthorized_path?(req.path)
        end
      end
    end
  end
end
