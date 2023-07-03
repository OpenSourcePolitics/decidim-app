# frozen_string_literal: true

require "decidim-app/k8s/manager"

module DecidimApp
  module K8s
    module Commands
      class Admin
        def self.run(configuration, organization)
          new(configuration, organization).run
        end

        def initialize(configuration, organization)
          @configuration = configuration
          @organization = organization
        end

        def run
          Decidim::User.find_or_initialize_by(email: @configuration["email"], organization: @organization).tap do |admin|
            admin.skip_confirmation!
            admin.update!(@configuration.merge({ tos_agreement: "1",
                                                 admin: true,
                                                 email_on_notification: admin.email_on_notification || true,
                                                 newsletter_notifications_at: admin.confirmed_at || Time.zone.now,
                                                 admin_terms_accepted_at: admin.confirmed_at || Time.zone.now,
                                                 confirmed_at: admin.confirmed_at || Time.zone.now }))
          end
        end
      end
    end
  end
end
