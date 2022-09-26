# frozen_string_literal: true

if Rails.env.production?
  
  # Remove the original throttle fron decidim-core
  # see https://github.com/decidim/decidim/blob/release/0.26-stable/decidim-core/config/initializers/rack_attack.rb#L19
  Rails.application.config.after_initialize do
    Rack::Attack.throttles.delete("requests by ip")
  end
  
  Rack::Attack.throttle("req/ip",
                        limit: Decidim.throttling_max_requests,
                        period: Decidim.throttling_period) do |req|
    next if req.path.start_with?("/decidim-packs")
    next if req.path.start_with?("/rails/active_storage")

    rack_logger = Logger.new(Rails.root.join("log/rack_attack.log"))
    rack_logger.warn("[Rack::Attack] [THROTTLE - req / ip] | #{req.ip} | #{req.path} | #{req.GET}")

    req.ip
  end
end
