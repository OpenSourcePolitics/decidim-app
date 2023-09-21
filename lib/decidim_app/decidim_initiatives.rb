# frozen_string_literal: true

module DecidimApp
  class DecidimInitiatives
    def self.decidim_initiatives_enabled?
      defined?(Decidim::Initiatives)
    end

    def self.apply_configuration
      Decidim::Initiatives.configure do |c|
        c.creation_enabled = creation_enabled? unless Rails.application.secrets.dig(:decidim, :initiatives, :creation_enabled) == "auto"
        c.similarity_threshold = similarity_threshold
        c.similarity_limit = similarity_limit
        c.minimum_committee_members = minimum_committee_members
        c.default_signature_time_period_length = default_signature_time_period_length
        c.default_components = default_components
        c.first_notification_percentage = first_notification_percentage
        c.second_notification_percentage = second_notification_percentage
        c.stats_cache_expiration_time = stats_cache_expiration_time
        c.max_time_in_validating_state = max_time_in_validating_state
        c.print_enabled = print_enabled? unless Rails.application.secrets.dig(:decidim, :initiatives, :print_enabled) == "auto"
        c.do_not_require_authorization = do_not_require_authorization? unless Rails.application.secrets.dig(:decidim, :initiatives, :do_not_require_authorization) == "auto"
      end
    end

    def self.creation_enabled?
      Rails.application.secrets.dig(:decidim, :initiatives, :creation_enabled).present?
    end

    def self.similarity_threshold
      Rails.application.secrets.dig(:decidim, :initiatives, :similarity_threshold).presence || 0.25
    end

    def self.similarity_limit
      Rails.application.secrets.dig(:decidim, :initiatives, :similarity_limit).presence || 5
    end

    def self.minimum_committee_members
      Rails.application.secrets.dig(:decidim, :initiatives, :minimum_committee_members).presence || 2
    end

    def self.default_signature_time_period_length
      Rails.application.secrets.dig(:decidim, :initiatives, :default_signature_time_period_length).presence || 120
    end

    # When INITIATIVES_DEFAULT_COMPONENTS=[]
    # Value is : ["[]"]
    # We must prevent this
    def self.default_components
      if Rails.application.secrets.dig(:decidim, :initiatives, :default_components) == ["[]"]
        []
      else
        Rails.application.secrets.dig(:decidim, :initiatives, :default_components)
      end
    end

    def self.first_notification_percentage
      Rails.application.secrets.dig(:decidim, :initiatives, :first_notification_percentage).presence || 33
    end

    def self.second_notification_percentage
      Rails.application.secrets.dig(:decidim, :initiatives, :second_notification_percentage).presence || 66
    end

    def self.stats_cache_expiration_time
      Rails.application.secrets.dig(:decidim, :initiatives, :stats_cache_expiration_time).to_i.minutes
    end

    def self.max_time_in_validating_state
      Rails.application.secrets.dig(:decidim, :initiatives, :max_time_in_validating_state).to_i.days
    end

    def self.print_enabled?
      Rails.application.secrets.dig(:decidim, :initiatives, :print_enabled).present?
    end

    def self.do_not_require_authorization?
      Rails.application.secrets.dig(:decidim, :initiatives, :do_not_require_authorization).present?
    end
  end
end
