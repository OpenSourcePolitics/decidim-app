# frozen_string_literal: true

module DecidimApp
  module Config
    def self.proxy_present?
      trusted_proxies.any?
    end

    def self.trusted_proxies
      Rails.application.secrets.dig(:decidim, :rack_attack, :trusted_proxies).presence || []
    end
  end
end
