# frozen_string_literal: true

if Rails.application.secrets.dig(:omniauth, :publik).present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :publik,
      setup: lambda { |env|
        request = Rack::Request.new(env)
        organization = Decidim::Organization.find_by(host: request.host)
        provider_config = organization.enabled_omniauth_providers[:publik]
        env["omniauth.strategy"].options[:client_id] = provider_config[:client_id]
        env["omniauth.strategy"].options[:client_secret] = provider_config[:client_secret]
        env["omniauth.strategy"].options[:site] = provider_config[:site_url]
      },
      scope: "openid email profile"
    )
  end
end
