# frozen_string_literal: true

if Rails.env.production?
  class Rack::Attack
    throttle("req/ip", limit: Decidim.throttling_max_requests, period: Decidim.throttling_max_requests) do |req|
      Rails.logger.warn("[Rack::Attack] [THROTTLE - req / ip] :: #{req.ip} :: #{req.path} :: #{req.GET}")
      req.ip unless req.path.start_with?("/assets")
    end
  end
end

