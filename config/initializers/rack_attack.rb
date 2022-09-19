# frozen_string_literal: true

if Rails.env.production?
  Rack::Attack.throttle("req/ip",
                        limit: Decidim.throttling_max_requests,
                        period: Decidim.throttling_period) do |req|
    next if req.path.start_with?("/assets")
    next if req.path.start_with?("/rails/active_storage")

    rack_logger = Logger.new(Rails.root.join("log/rack_attack.log"))
    rack_logger.warn("[Rack::Attack] [THROTTLE - req / ip] | #{req.ip} | #{req.path} | #{req.GET}")

    req.ip
  end
end
