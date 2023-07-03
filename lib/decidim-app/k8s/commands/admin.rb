# frozen_string_literal: true

require "decidim-app/k8s/manager"

module DecidimApp
  module K8s
    module Commands
      class Admin
        include Decidim::FormFactory

        def self.run(configuration, organization)
          new(configuration, organization).run
        end

        def initialize(configuration, organization)
          @configuration = configuration
          @organization = organization
        end

        def run
          mapped_attributes = form(Decidim::AccountForm).from_model(existing_admin).attributes_with_values.except(:avatar)
          form = form(Decidim::AccountForm).from_params(mapped_attributes.merge(default_params).merge(@configuration)).with_context(current_user: existing_admin, current_organization: @organization)

          Decidim::UpdateAccount.call(existing_admin, form) do
            on(:ok) do
              K8s::Manager.logger.info("Admin user #{form.nickname} updated")
            end

            on(:invalid) do
              K8s::Manager.logger.info("Admin user #{form.nickname} could not be updated")
              form.tap(&:valid?).errors.messages.each do |error|
                K8s::Manager.logger.info(error)
              end
            end
          end

          existing_admin.reload
        end

        def existing_admin
          @existing_admin ||= Decidim::User.find_by(email: @configuration[:email], organization: @organization).tap(&:skip_confirmation!)
        end

        def default_params
          @default_params ||= {
            password_confirmation: @configuration[:password],
            tos_agreement: "1",
            email_on_notification: existing_admin.email_on_notification || true,
            newsletter_notifications_at: existing_admin.confirmed_at || Time.zone.now,
            admin_terms_accepted_at: existing_admin.confirmed_at || Time.zone.now,
            confirmed_at: existing_admin.confirmed_at || Time.zone.now
          }
        end
      end
    end
  end
end
