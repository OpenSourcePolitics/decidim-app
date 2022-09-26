# frozen_string_literal: true


Rack::Attack.enabled = ENV['ENABLE_RACK_ATTACK'] || Rails.env.production?
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
