# frozen_string_literal: true

require "decidim_app/k8s/manager"
require "decidim/core"

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
          mapped_attributes = Decidim::AccountForm.from_model(existing_admin)
                                                  .attributes_with_values
                                                  .except(:avatar)
          form = Decidim::AccountForm.from_params(mapped_attributes.merge(admin_params))
                                     .with_context(current_user: existing_admin,
                                                   current_organization: @organization)

          Decidim::UpdateAccount.call(existing_admin, form) do
            on(:ok) do
              K8s::Manager.logger.info("Admin user #{form.nickname} updated")
            end

            on(:invalid) do
              K8s::Manager.logger.info("Admin user #{form.nickname} could not be updated")
              form.tap(&:valid?).errors.messages.each do |error|
                K8s::Manager.logger.info(error)
              end

              raise "Admin user #{form.nickname} could not be updated"
            end
          end

          existing_admin.reload
        end

        def existing_admin
          @existing_admin ||= Decidim::User.find_by(email: @configuration[:email], organization: @organization).tap(&:skip_confirmation!)
        end

        def admin_params
          @admin_params ||= {
            password_confirmation: @configuration[:password],
            tos_agreement: "1",
            newsletter_notifications_at: existing_admin.confirmed_at || Time.zone.now,
            admin_terms_accepted_at: existing_admin.confirmed_at || Time.zone.now,
            confirmed_at: existing_admin.confirmed_at || Time.zone.now
          }.merge(@configuration)
        end
      end
    end
  end
end
