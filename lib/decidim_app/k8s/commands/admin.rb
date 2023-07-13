# frozen_string_literal: true

require "decidim_app/k8s/manager"
require "decidim/core"

module DecidimApp
  module K8s
    module Commands
      class Admin < Rectify::Command
        attr_accessor :status

        def initialize(configuration, organization)
          @configuration = configuration
          @organization = organization

          @status = {}
          @topic = :admin_user
        end

        def call
          mapped_attributes = Decidim::AccountForm.from_model(existing_admin)
                                                  .attributes_with_values
                                                  .except(:avatar)
          form = Decidim::AccountForm.from_params(mapped_attributes.merge(admin_params))
                                     .with_context(current_user: existing_admin,
                                                   current_organization: @organization)

          Decidim::UpdateAccount.call(existing_admin, form) do
            on(:ok) do
              register_status(:update, :ok)
            end

            on(:invalid) do
              register_status(:update, :invalid, form.tap(&:valid?).errors.messages)
            end
          end

          return broadcast(:invalid, @status, nil) if @status.any? { |_, status| status[:status] != :ok }

          broadcast(:ok, @status, existing_admin.reload)
        end

        def register_status(action, status, messages = [])
          @status.deep_merge!(@topic => { action => { status: status, messages: messages }})
        end

        def existing_admin
          @existing_admin ||= Decidim::User.find_by(email: @configuration[:email], organization: @organization).tap(&:skip_confirmation!)
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
