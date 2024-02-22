# frozen_string_literal: true

require "sentry-ruby"
require "json"
require "decidim_app/sentry_setup"

module SentrySetup
  class << self
    def init
      return unless Rails.application.secrets.dig(:sentry, :enabled)

      Sentry.init do |config|
        config.dsn = Rails.application.secrets.dig(:sentry, :dsn)
        config.breadcrumbs_logger = [:active_support_logger, :http_logger]

        config.traces_sample_rate = sample_rate.to_f

        config.traces_sampler = ->(sampling_context) { sample_trace(sampling_context) }
      end

      Sentry.set_tags("server.hostname": hostname) if hostname.present?
      Sentry.set_tags("server.ip": ip) if ip.present?
    end

    private

    def sample_trace(sampling_context)
      transaction_context = sampling_context[:transaction_context]
      op = transaction_context[:op]
      transaction_name = transaction_context[:name]

      if op =~ /http/ && transaction_name == "/health_check"
        0.0
      else
        sample_rate.to_f
      end
    end

    def server_metadata
      JSON.parse(`scw-metadata-json`)
    rescue Errno::ENOENT, TypeError
      {}
    end

    def hostname
      server_metadata["hostname"]
    end

    def ip
      server_metadata.dig("public_ip", "address")
    end

    def sample_rate
      Sidekiq.server? ? ENV.fetch("SENTRY_SIDEKIQ_SAMPLE_RATE", "0.1") : ENV.fetch("SENTRY_SAMPLE_RATE", "0.5")
    end
  end
end
