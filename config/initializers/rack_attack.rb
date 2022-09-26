# frozen_string_literal: true

# Enabled by default in production
# Can be deactivated with 'ENABLE_RACK_ATTACK="2"'
Rack::Attack.enabled = (ENV['ENABLE_RACK_ATTACK'] == "1") || Rails.env.production?

# By default use the memory store for inspecting requests
# Better to use MemCached or Redis in production mode
if !ENV['MEMCACHEDCLOUD_SERVERS'] || Rails.env.test?
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
end

Rack::Attack.throttle("req/ip",
                      limit: Decidim.throttling_max_requests,
                      period: Decidim.throttling_period) do |req|

  unless req.path.start_with?("/assets") || req.path.start_with?("/rails/active_storage")
    rack_logger = Logger.new(Rails.root.join("log/rack_attack.log"))

    request_uuid = req.env['action_dispatch.request_id']

    params = {
      "ip" => req.ip,
      "path" => req.path,
      "get" => req.GET,
      "post" => req.POST,
      "host" => req.host,
      "referer" => req.referer
    }

    rack_logger.warn("[#{request_uuid}] #{params}")

    req.ip
  end
end
