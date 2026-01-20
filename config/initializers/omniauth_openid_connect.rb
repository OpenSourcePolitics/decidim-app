# frozen_string_literal: true

require "decidim_app/omniauth/openid_connect_utils"

if ENV["OMNIAUTH_OPENID_CONNECT_CLIENT_OPTIONS_SECRET"].present?
  OmniAuth.config.logger = Rails.logger
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :openid_connect,
      setup: lambda { |env|
        DecidimApp::Omniauth::OpenidConnectUtils.setup(:openid_connect, env)
      }
    )
  end
end
