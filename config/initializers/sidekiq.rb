# frozen_string_literal: true

Sidekiq.configure_client do |config|
  config.redis = {
    network_timeout: 5,
    pool_timeout: 5,
    reconnect_attempts: ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 0)
  }
end
