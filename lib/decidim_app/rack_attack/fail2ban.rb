# frozen_string_literal: true

module DecidimApp
  module RackAttack
    module Fail2ban
      UNAUTHORIZED_FAIL2BAN_PATHS = ["/etc/passwd", "/wp-admin/", "/wp-login/", "SELECT", "CONCAT", "UNION%20SELECT", "/.git/"].freeze

      def self.enabled?
        Rails.application.secrets.dig(:decidim, :rack_attack, :fail2ban, :enabled) == 1
      end

      # If true: request must be sent to Fail2ban service
      def self.unauthorized_path?(path)
        UNAUTHORIZED_FAIL2BAN_PATHS.map { |unauthorized| path.include?(unauthorized) }.include?(true)
      end
    end
  end
end
