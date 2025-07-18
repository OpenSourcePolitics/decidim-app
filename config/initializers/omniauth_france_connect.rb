# frozen_string_literal: true

require "decidim_app/omniauth/openid_connect_utils"
require "omniauth/strategies/france_connect"

if Rails.application.secrets.dig(:omniauth, :france_connect).present?
  OmniAuth.config.logger = Rails.logger
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :france_connect,
      setup: lambda { |env|
        DecidimApp::Omniauth::OpenidConnectUtils.setup(:france_connect, env)
      }
    )
  end
end
