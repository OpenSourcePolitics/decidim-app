# frozen_string_literal: true

if Rails.env.production?
  class Rack::Attack
    # source: https://github.com/rack/rack-attack/blob/4d201f7e425f99a0c1f0956fbcc935614d695308/examples/rack_attack.rb#L5
    throttle("req/ip", limit: 10, period: 1) do |req|
      Rails.logger.warn("[Rack::Attack] [THROTTLE - req / ip] :: #{req.ip} :: #{req.path} :: #{req.GET}")
      req.ip unless req.path.start_with?("/assets")
    end
  end
end
