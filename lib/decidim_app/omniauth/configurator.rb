# frozen_string_literal: true

module DecidimApp
  module Omniauth
    class Configurator
      attr_reader :provider, :database_settings, :strategy_options, :rails_secrets

      def initialize(provider, env)
        request = Rack::Request.new(env)
        organization = env["decidim.current_organization"].presence || Decidim::Organization.find_by(host: request.host)
        @provider = provider
        @strategy_options = if env["omniauth.strategy"].present?
                              env["omniauth.strategy"].options
                            else
                              OmniAuth::Strategies.const_get(
                                OmniAuth::Utils.camelize(provider).to_s,
                                false
                              ).default_options
                            end
        @database_settings = organization.enabled_omniauth_providers[provider.to_sym]
        @rails_secrets = load_provider_secrets(provider)
      end

      def set_value(key, forced_value: nil, path: nil, transform: ->(value) { value })
        value = if forced_value.nil?
                  transform.call(find_value(key.to_sym))
                else
                  forced_value
                end
        return if value.nil?

        if path.present?
          path_array = path.split(".").map(&:to_sym)
          strategy_options.dig(*path_array[0..-2])[path_array.last] = value
        else
          strategy_options[key.to_sym] = value
        end
      end

      def find_value(key)
        if database_settings&.dig(key).present?
          database_settings[key]
        elsif rails_secrets&.dig(key).present?
          rails_secrets[key]
        end
      end

      def options(key)
        find_value(key) || strategy_options[key]
      end

      def manage_boolean(value)
        [true, "true", "TRUE", 1, "1"].include?(value) if value.present?
      end

      private

      def load_provider_secrets(provider)
        case provider.to_s
        when "france_connect"
          {
            enabled: ENV["OMNIAUTH_FRANCE_CONNECT_CLIENT_OPTIONS_SECRET"].present?,
            icon: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_ICON_PATH", nil),
            icon_hover_path: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_ICON_HOVER_PATH", nil),
            display_name: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_DISPLAY_NAME", nil),
            issuer: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_ISSUER", nil),
            client_options_identifier: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_CLIENT_OPTIONS_IDENTIFIER", nil),
            client_options_secret: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_CLIENT_OPTIONS_SECRET", nil),
            client_options_redirect_uri: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_CLIENT_OPTIONS_REDIRECT_URI", nil),
            scope: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_SCOPE", nil),
            acr_values: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_ACR_VALUES", nil),
            client_signing_alg: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_CLIENT_SIGNING_ALG", nil),
            logout_policy: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_LOGOUT_POLICY", nil),
            logout_path: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_LOGOUT_PATH", nil),
            post_logout_redirect_uri: ENV.fetch("OMNIAUTH_FRANCE_CONNECT_POST_LOGOUT_REDIRECT_URI", nil)
          }.compact
        when "openid_connect"
          {
            enabled: ENV["OMNIAUTH_OPENID_CONNECT_CLIENT_OPTIONS_SECRET"].present?,
            icon: ENV.fetch("OMNIAUTH_OPENID_CONNECT_ICON_PATH", nil),
            display_name: ENV.fetch("OMNIAUTH_OPENID_CONNECT_DISPLAY_NAME", nil),
            issuer: ENV.fetch("OMNIAUTH_OPENID_CONNECT_ISSUER", nil),
            discovery: ENV.fetch("OMNIAUTH_OPENID_CONNECT_DISCOVERY", nil),
            client_options_identifier: ENV.fetch("OMNIAUTH_OPENID_CONNECT_CLIENT_OPTIONS_IDENTIFIER", nil),
            client_options_secret: ENV.fetch("OMNIAUTH_OPENID_CONNECT_CLIENT_OPTIONS_SECRET", nil),
            client_options_redirect_uri: ENV.fetch("OMNIAUTH_OPENID_CONNECT_CLIENT_OPTIONS_REDIRECT_URI", nil),
            scope: ENV.fetch("OMNIAUTH_OPENID_CONNECT_SCOPE", nil),
            response_type: ENV.fetch("OMNIAUTH_OPENID_CONNECT_RESPONSE_TYPE", nil),
            acr_values: ENV.fetch("OMNIAUTH_OPENID_CONNECT_ACR_VALUES", nil),
            client_auth_method: ENV.fetch("OMNIAUTH_OPENID_CONNECT_CLIENT_AUTH_METHOD", nil),
            client_signing_alg: ENV.fetch("OMNIAUTH_OPENID_CONNECT_CLIENT_SIGNING_ALG", nil),
            logout_policy: ENV.fetch("OMNIAUTH_OPENID_CONNECT_LOGOUT_POLICY", nil),
            logout_path: ENV.fetch("OMNIAUTH_OPENID_CONNECT_LOGOUT_PATH", nil),
            post_logout_redirect_uri: ENV.fetch("OMNIAUTH_OPENID_CONNECT_POST_LOGOUT_REDIRECT_URI", nil),
            uid_field: ENV.fetch("OMNIAUTH_OPENID_CONNECT_UID_FIELD", nil)
          }.compact
        when "publik"
          {
            enabled: ENV["OMNIAUTH_PUBLIK_CLIENT_SECRET"].present?,
            icon_path: ENV.fetch("OMNIAUTH_PUBLIK_ICON_PATH", nil),
            display_name: ENV.fetch("OMNIAUTH_PUBLIK_DISPLAY_NAME", nil),
            client_id: ENV.fetch("OMNIAUTH_PUBLIK_CLIENT_ID", nil),
            client_secret: ENV.fetch("OMNIAUTH_PUBLIK_CLIENT_SECRET", nil),
            site_url: ENV.fetch("OMNIAUTH_PUBLIK_SITE_URL", nil)
          }.compact
        when "cultuur_connect"
          {
            enabled: false,
            icon_path: ENV.fetch("OMNIAUTH_CCO_ICON_PATH", nil),
            client_id: ENV.fetch("OMNIAUTH_CCO_CLIENT_ID", nil),
            client_secret: ENV.fetch("OMNIAUTH_CCO_CLIENT_SECRET", nil),
            site_url: ENV.fetch("OMNIAUTH_SITE_URL", nil)
          }.compact
        else
          raise ArgumentError, "Omniauth provider '#{provider}' is not configured. Supported providers are: france_connect, openid_connect, publik, cultuur_connect"
        end
      end
    end
  end
end
