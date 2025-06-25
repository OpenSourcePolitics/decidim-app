# frozen_string_literal: true

module DecidimApp
  module Omniauth
    class Utils
      def self.find_value(key, settings, secrets)
        if settings&.dig(key).present?
          settings[key]
        elsif secrets&.dig(key).present?
          secrets[key]
        end
      end

      def self.provider_settings(env, provider)
        request = Rack::Request.new(env)
        organization = env["decidim.current_organization"].presence || Decidim::Organization.find_by(host: request.host)
        organization.enabled_omniauth_providers[provider.to_sym]
      end
    end
  end
end
