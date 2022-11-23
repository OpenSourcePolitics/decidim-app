# frozen_string_literal: true

require "sentry-ruby"
require "json"

module SentrySetup
  class << self
    def init
      return unless Rails.application.secrets.dig(:sentry, :enabled)

      Sentry.init do |config|
        config.dsn = Rails.application.secrets.dig(:sentry, :dsn)
        config.breadcrumbs_logger = [:active_support_logger]

        # To activate performance monitoring, set one of these options.
        # We recommend adjusting the value in production:
        config.traces_sample_rate = ENV.fetch("SENTRY_SAMPLE_RATE", 1.0)
      end

      Sentry.set_tags('server.hostname': hostname) if hostname.present?
      Sentry.set_tags('server.ip': ip) if ip.present?
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
  end
end
