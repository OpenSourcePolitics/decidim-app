# frozen_string_literal: true
require "omniauth/strategies/cultuur_connect"

Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth.config.logger = Rails.logger

  omniauth_config = Rails.application.secrets.dig(:omniauth)

  if omniauth_config[:cultuur_connect].present?
    provider(
      :cultuur_connect,
      setup: setup_provider_proc(:cultuur_connect,
                                 client_id: :client_id,
                                 client_secret: :client_secret,
                                 site: :site
      )
    )
  end
end
