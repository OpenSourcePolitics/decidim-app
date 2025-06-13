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
        @rails_secrets = Rails.application.secrets.dig(:omniauth, provider.to_sym)

        # Rails.logger.debug { "Configuring omniauth provider: #{provider} for organization: (#{organization.id}) #{organization.host}" }
        # Rails.logger.debug { "Strategy default options: #{strategy_options.inspect}" }
        # Rails.logger.debug { "Database settings: #{database_settings.inspect}" }
        # Rails.logger.debug { "Rails secrets: #{rails_secrets.inspect}" }
      end

      def set_value(key, forced_value: nil, path: nil, transform: ->(value) { value })
        value = if forced_value.nil? # false and "" are valid values
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
    end
  end
end
