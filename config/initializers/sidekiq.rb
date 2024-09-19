# frozen_string_literal: true


return unless const_defined?(Sidekiq)

Rails.logger.warn "Configuring Sidekiq..."

Sidekiq.configure_client do |config|
  config.redis = {
    network_timeout: 10,
    pool_timeout: 10,
    reconnect_attempts: 0
  }
end
