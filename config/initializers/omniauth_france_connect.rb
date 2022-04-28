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
      scope: [:openid, :birthdate]
    )
  end
end

if Rails.application.secrets.dig(:omniauth, :france_connect_profile).present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :france_connect_profile,
      setup: setup_provider_proc(:france_connect_profile,
                                 site: :site,
                                 client_id: :client_id,
                                 client_secret: :client_secret,
                                 end_session_endpoint: :end_session_endpoint,
                                 icon_path: :icon_path,
                                 button_path: :button_path,
                                 provider_name: :provider_name,
                                 minimum_age: :minimum_age)
    )
  end
end

if Rails.application.secrets.dig(:omniauth, :france_connect_uid).present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :france_connect_uid,
      setup: setup_provider_proc(:france_connect_uid,
                                 site: :site,
                                 client_id: :client_id,
                                 client_secret: :client_secret,
                                 end_session_endpoint: :end_session_endpoint,
                                 icon_path: :icon_path,
                                 button_path: :button_path,
                                 provider_name: :provider_name,
                                 minimum_age: :minimum_age)
    )
  end
end
