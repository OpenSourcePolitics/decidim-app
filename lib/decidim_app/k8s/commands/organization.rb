# frozen_string_literal: true

require "decidim_app/k8s/command"

module DecidimApp
  module K8s
    module Commands
      class Organization < DecidimApp::K8s::Command
        register_topic :organization

        def initialize(organization, default_admin)
          @organization = organization
          @default_admin_name = default_admin[:name]
          @default_admin_email = default_admin[:email]
        end

        def call
          if existing_organization
            update
          else
            install
          end

          broadcast_status(existing_organization)
        end

        def install
          form = Decidim::System::RegisterOrganizationForm.from_params(
            @organization.merge(
              organization_admin_email: @default_admin_email,
              organization_admin_name: @default_admin_name
            )
          )

          Decidim::System::RegisterOrganization.call(form) do
            on(:ok) do
              register_status(:created, :ok)

              update
            end

            on(:invalid) do
              register_status(:created, :invalid, errors_for(form))
            end
          end
        end

        def update
          form = Decidim::System::UpdateOrganizationForm.from_params(update_params)

          Decidim::System::UpdateOrganization.call(existing_organization.id, form) do
            on(:ok) do
              register_status(:updated, :ok)
            end

            on(:invalid) do
              register_status(:updated, :invalid, errors_for(form))
            end
          end
        end

        def existing_organization
          @existing_organization ||= (Decidim::Organization.find_by(name: @organization[:name]) || Decidim::Organization.find_by(host: @organization[:host]))
        end

        def existing_organization_attrs
          Decidim::System::UpdateOrganizationForm.from_model(existing_organization).attributes_with_values.deep_symbolize_keys
        end

        def update_params
          params = existing_organization_attrs.deep_merge(
            @organization.except(:smtp_settings, :omniauth_settings)
          ).merge(id: existing_organization.id)

          @organization.fetch(:smtp_settings, {}).each do |key, value|
            params.merge!(key => value)
          end

          @organization.fetch(:omniauth_settings, {}).each do |provider, config|
            config.each do |key, value|
              params.merge!("omniauth_settings_#{provider}_#{key}" => value)
            end
          end

          params[:encrypted_password] = nil if @organization.dig(:smtp_settings, :password).present?

          params
        end
      end
    end
  end
end
