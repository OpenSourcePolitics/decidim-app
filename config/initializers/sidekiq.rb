# frozen_string_literal: true

Sidekiq.configure_client do |config|
  config.redis = {
    network_timeout: ENV.fetch("REDIS_NETWORK_TIMEOUT", 10),
    pool_timeout: ENV.fetch("REDIS_POOL_TIMEOUT", 10),
    reconnect_attempts: ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 1)
  }
end
