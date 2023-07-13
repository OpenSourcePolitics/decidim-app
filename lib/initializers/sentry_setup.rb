# frozen_string_literal: true

require "sentry-ruby"
require "json"

module SentrySetup
  class << self
    def init
      return unless Rails.application.secrets.dig(:sentry, :enabled)

      Sentry.init do |config|
        config.dsn = Rails.application.secrets.dig(:sentry, :dsn)
        config.breadcrumbs_logger = [:active_support_logger, :http_logger]

        config.traces_sample_rate = sample_rate.to_f
      end

      Sentry.set_tags("server.hostname": hostname) if hostname.present?
      Sentry.set_tags("server.ip": ip) if ip.present?
    end

    private

    def server_metadata
      JSON.parse(`scw-metadata-json`)
    rescue Errno::ENOENT, TypeError
      nil
    end

    def hostname
      server_metadata&.dig("hostname")
    end

    def ip
      server_metadata&.dig("public_ip", "address")
    end

    def sample_rate
      Sidekiq.server? ? ENV.fetch("SENTRY_SIDEKIQ_SAMPLE_RATE", "0.1") : ENV.fetch("SENTRY_SAMPLE_RATE", "0.5")
    end
  end
end
