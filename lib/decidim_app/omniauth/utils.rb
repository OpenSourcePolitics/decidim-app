# frozen_string_literal: true

module DecidimApp
  module Omniauth
    class Utils
      def self.find_value(key, provider_config, rails_secrets)
        if provider_config&.dig(key).present?
          provider_config[key]
        elsif rails_secrets&.dig(key).present?
          rails_secrets[key]
        end
      end
    end
  end
end
