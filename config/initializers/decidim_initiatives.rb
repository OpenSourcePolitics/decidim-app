# frozen_string_literal: true

if defined?(Decidim::Initiatives)
  Decidim::Initiatives.configure do |config|
    unless Rails.application.secrets.dig(:decidim, :initiatives, :creation_enabled) == "auto"
      config.creation_enabled = Rails.application.secrets.dig(:decidim, :initiatives, :creation_enabled).present?
    end
    config.similarity_threshold = Rails.application.secrets.dig(:decidim, :initiatives, :similarity_threshold).presence || 0.25
    config.similarity_limit = Rails.application.secrets.dig(:decidim, :initiatives, :similarity_limit).presence || 5
    config.minimum_committee_members = Rails.application.secrets.dig(:decidim, :initiatives, :minimum_committee_members).presence || 2
    config.default_signature_time_period_length = Rails.application.secrets.dig(:decidim, :initiatives, :default_signature_time_period_length).presence || 120
    config.default_components = Rails.application.secrets.dig(:decidim, :initiatives, :default_components)
    config.first_notification_percentage = Rails.application.secrets.dig(:decidim, :initiatives, :first_notification_percentage).presence || 33
    config.second_notification_percentage = Rails.application.secrets.dig(:decidim, :initiatives, :second_notification_percentage).presence || 66
    config.stats_cache_expiration_time = Rails.application.secrets.dig(:decidim, :initiatives, :stats_cache_expiration_time).to_i.minutes
    config.max_time_in_validating_state = Rails.application.secrets.dig(:decidim, :initiatives, :max_time_in_validating_state).to_i.days
    unless Rails.application.secrets.dig(:decidim, :initiatives, :print_enabled) == "auto"
      config.print_enabled = Rails.application.secrets.dig(:decidim, :initiatives, :print_enabled).present?
    end
    config.do_not_require_authorization = Rails.application.secrets.dig(:decidim, :initiatives, :do_not_require_authorization).present?
  end
end
