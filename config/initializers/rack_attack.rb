# frozen_string_literal: true

if Rails.env.production?
  Rack::Attack.throttle("req/ip", limit: Decidim.throttling_max_requests, period: Decidim.throttling_max_requests) do |req|
    unless req.path.start_with?("/assets") || req.path.start_with?("/rails/active_storage")
      Rails.logger.warn("[Rack::Attack] [THROTTLE - req / ip] :: #{req.ip} :: #{req.path} :: #{req.GET}")
      req.ip
    end
  end
end
