# frozen_string_literal: true

module DecidimApp
  module RackAttack
    def self.rack_enabled?
      setting = Rails.application.secrets.dig(:decidim, :rack_attack, :enabled)
      return setting == "1" if setting.present?

      Rails.env.production?
    end
  end
end
