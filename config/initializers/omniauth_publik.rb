# frozen_string_literal: true

if ENV["OMNIAUTH_PUBLIK_CLIENT_SECRET"].present?
  Decidim.configure do |config|
    config.omniauth_providers[:publik] = {
      enabled: true,
      client_id: ENV.fetch("OMNIAUTH_PUBLIK_CLIENT_ID", nil),
      client_secret: ENV["OMNIAUTH_PUBLIK_CLIENT_SECRET"],
      site_url: ENV.fetch("OMNIAUTH_PUBLIK_SITE_URL", nil)
    }
  end

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

Rails.application.config.after_initialize do
  Decidim.icons.register(
    name: "publik-fill",
    icon: "publik-fill",
    category: "system",
    description: "Publik authentication provider icon",
    engine: :core
  )
end
