# frozen_string_literal: true

Sidekiq.configure_client do |config|
  config.redis = {
    network_timeout: ENV.fetch("REDIS_NETWORK_TIMEOUT", 0),
    pool_timeout: ENV.fetch("REDIS_POOL_TIMEOUT", 0),
    reconnect_attempts: ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 0)
  }
end
