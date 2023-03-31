# frozen_string_literal: true

return unless Rails.env.production?
  SidekiqAlive.setup do |config|
    config.path = "/sidekiq_alive"
  end
end
