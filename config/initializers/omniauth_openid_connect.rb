# frozen_string_literal: true

require "decidim_app/omniauth/openid_connect_utils"

if Rails.application.secrets.dig(:omniauth, :openid_connect).present?
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
