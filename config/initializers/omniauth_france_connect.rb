# frozen_string_literal: true

if Rails.application.secrets.dig(:omniauth, :france_connect).present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :france_connect,
      setup: lambda { |env|
        request = Rack::Request.new(env)
        organization = Decidim::Organization.find_by(host: request.host)
        provider_config = organization.enabled_omniauth_providers[:france_connect]
        env["omniauth.strategy"].options[:client_id] = provider_config[:client_id]
        env["omniauth.strategy"].options[:client_secret] = provider_config[:client_secret]
        env["omniauth.strategy"].options[:site] = provider_config[:site_url]
      },
      scope: [:email, :openid, :birthdate, :given_name, :family_name]
    )
  end
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :france_connect_profile,
      setup: lambda { |env|
        request = Rack::Request.new(env)
        organization = Decidim::Organization.find_by(host: request.host)
        provider_config = organization.enabled_omniauth_providers[:france_connect_profile]
        env["omniauth.strategy"].options[:client_id] = provider_config[:client_id]
        env["omniauth.strategy"].options[:client_secret] = provider_config[:client_secret]
        env["omniauth.strategy"].options[:site] = provider_config[:site_url]
      },
      scope: [:email, :openid, :birthdate, :given_name, :family_name, :preferred_username]
    )
  end
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :france_connect_uid,
      setup: lambda { |env|
        request = Rack::Request.new(env)
        organization = Decidim::Organization.find_by(host: request.host)
        provider_config = organization.enabled_omniauth_providers[:france_connect_uid]
        env["omniauth.strategy"].options[:client_id] = provider_config[:client_id]
        env["omniauth.strategy"].options[:client_secret] = provider_config[:client_secret]
        env["omniauth.strategy"].options[:site] = provider_config[:site_url]
      },
      scope: [:openid]
    )
  end
end
