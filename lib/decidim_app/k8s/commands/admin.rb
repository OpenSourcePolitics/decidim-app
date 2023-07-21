# frozen_string_literal: true

require "decidim_app/k8s/command"
require "decidim/core"

module DecidimApp
  module K8s
    module Commands
      class Admin < DecidimApp::K8s::Command
        register_topic :admin

        def initialize(configuration, organization)
          @configuration = configuration
          @organization = organization
        end

        def call
          install_or_update

          broadcast_status(existing_admin)
        end

        def install_or_update
          form = Decidim::AccountForm.from_params(update_params)
                                     .with_context(current_user: existing_admin,
                                                   current_organization: @organization)

          Decidim::UpdateAccount.call(existing_admin, form) do
            on(:ok) do
              register_status(:updated, :ok)
            end

            on(:invalid) do
              register_status(:updated, :invalid, errors_for(form))
            end
          end
        end

        def existing_admin
          @existing_admin ||= Decidim::User.find_by(email: @configuration[:email], organization: @organization).tap(&:skip_confirmation!)
        end

        def existing_admin_attributes
          Decidim::AccountForm.from_model(existing_admin)
                              .attributes_with_values
                              .except(:avatar)
        end

        def update_params
          existing_admin_attributes.merge(admin_params)
        end

        def admin_params
          @admin_params ||= {
            password_confirmation: @configuration[:password],
            tos_agreement: "1",
            email_on_notification: existing_admin.email_on_notification || true,
            newsletter_notifications_at: existing_admin.confirmed_at || Time.zone.now,
            admin_terms_accepted_at: existing_admin.confirmed_at || Time.zone.now,
            confirmed_at: existing_admin.confirmed_at || Time.zone.now
          }.merge(@configuration)
        end
      end
    end
  end
end
