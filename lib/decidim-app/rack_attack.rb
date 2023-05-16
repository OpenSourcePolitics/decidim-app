module DecidimApp
  module RackAttack
    def self.rack_enabled?
      (Rails.application.secrets.dig(:decidim, :rack_attack, :enabled) == 1) || Rails.env.production?
    end
  end
end
