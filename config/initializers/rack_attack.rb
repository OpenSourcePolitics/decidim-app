# frozen_string_literal: true

class Rack::Attack
  throttle("req/ip", limit: 100, period: 1.minute) do |req|
    Rails.logger.warn("[Rack::Attack] [THROTTLE - req / ip] :: #{req.ip} :: #{req.path} :: #{req.GET}")
    req.ip unless req.path.start_with?("/assets")
  end
end
