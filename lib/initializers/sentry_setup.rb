# frozen_string_literal: true

require "sentry-ruby"

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

    def hostname
      `hostname`.chomp

    rescue Errno::ENOENT
      nil
    end

    def ip
      return if hostname.blank?
      return unless system("hostname -I > /dev/null 2>&1")

      `hostname -I`.strip
                   .split(" ")
                   .first
    end
  end
end
