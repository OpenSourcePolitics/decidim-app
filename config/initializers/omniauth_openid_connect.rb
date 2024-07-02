# frozen_string_literal: true

require "decidim_app/omniauth/utils"

if Rails.application.secrets.dig(:omniauth, :openid_connect).present?
  OmniAuth.config.logger = Rails.logger
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :openid_connect,
      setup: lambda { |env|
        request = Rack::Request.new(env)
        organization = env["decidim.current_organization"].presence || Decidim::Organization.find_by(host: request.host)
        provider_config = organization.enabled_omniauth_providers[:openid_connect]

        discovery = DecidimApp::Omniauth::Utils.find_value(:discovery, provider_config, Rails.application.secrets.dig(:omniauth, :openid_connect))
        env["omniauth.strategy"].options[:discovery] = (discovery == "true") if discovery.present?

        %w(
          identifier
          secret
          redirect_uri
        ).map(&:to_sym).each do |key|
          value = DecidimApp::Omniauth::Utils.find_value(:"client_options_#{key}", provider_config, Rails.application.secrets.dig(:omniauth, :openid_connect))
          env["omniauth.strategy"].options[:client_options][key] = value if value.present?
        end

        if env["omniauth.strategy"].options[:client_options][:redirect_uri].blank?
          env["omniauth.strategy"].options[:client_options][:redirect_uri] = env["omniauth.strategy"].callback_url.split("?")[0]
        end

        %w(
          issuer
          response_type
          post_logout_redirect_uri
          uid_field
        ).map(&:to_sym).each do |key|
          value = DecidimApp::Omniauth::Utils.find_value(key, provider_config, Rails.application.secrets.dig(:omniauth, :openid_connect))
          env["omniauth.strategy"].options[key] = value if value.present?
        end

        scope = DecidimApp::Omniauth::Utils.find_value(:scope, provider_config, Rails.application.secrets.dig(:omniauth, :openid_connect))
        env["omniauth.strategy"].options[:scope] = scope.split if scope.present?
      }
    )
  end
end
