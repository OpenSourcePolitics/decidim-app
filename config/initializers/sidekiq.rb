# frozen_string_literal: true

Sidekiq.configure_client do |config|
  config.redis = {
    network_timeout: 10,
    pool_timeout: 10,
    reconnect_attempts: 0
  }
end
