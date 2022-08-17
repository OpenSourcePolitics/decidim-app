# frozen_string_literal: true

if Rails.env.production?
  Rack::Attack.throttle("req/ip", limit: Decidim.throttling_max_requests, period: Decidim.throttling_max_requests) do |req|
    req.ip unless req.path.start_with?("/assets") || req.path.start_with?("/rails/active_storage")
  end

  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]

    Rails.logger.warn("[Rack::Attack] [THROTTLE - req / ip] :: #{req.ip} :: #{req.path} :: #{req.GET}")
  end
end
