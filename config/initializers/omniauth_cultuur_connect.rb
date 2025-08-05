# frozen_string_literal: true

require "omniauth/strategies/cultuur_connect"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :cultuur_connect,
    setup: lambda { |env|
      request = Rack::Request.new(env)
      organization = env["decidim.current_organization"].presence || Decidim::Organization.find_by(host: request.host)
      provider_config = organization.enabled_omniauth_providers[:cultuur_connect]
      env["omniauth.strategy"].options[:client_id] = provider_config[:client_id]
      env["omniauth.strategy"].options[:client_secret] = provider_config[:client_secret]
      env["omniauth.strategy"].options[:client_options][:site] = provider_config[:site_url]
    }
  )
end
