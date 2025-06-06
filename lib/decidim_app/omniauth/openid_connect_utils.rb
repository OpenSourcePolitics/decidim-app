# frozen_string_literal: true

require "decidim_app/omniauth/configurator"

module DecidimApp
  module Omniauth
    class OpenidConnectUtils
      def self.setup(provider, env)
        configurator = Configurator.new(provider, env)
        configurator.set_value(:discovery, transform: ->(value) { configurator.manage_boolean(value) })

        %w(
          identifier
          secret
          redirect_uri
        ).map(&:to_sym).each do |key|
          configurator.set_value("client_options_#{key}", path: "client_options.#{key}")
        end

        if configurator.strategy_options[:client_options][:redirect_uri].blank?
          configurator.set_value(
            :redirect_uri,
            forced_value: env["omniauth.strategy"].callback_url.split("?")[0],
            path: "client_options.redirect_uri"
          )
        end

        %w(
          issuer
          response_type
          acr_values
          client_auth_method
          client_signing_alg
          logout_policy
          logout_path
          post_logout_redirect_uri
          uid_field
        ).map(&:to_sym).each do |key|
          configurator.set_value(key)
        end

        configurator.set_value(:scope, transform: ->(value) { value&.split(",")&.map(&:strip) })
      end
    end
  end
end
