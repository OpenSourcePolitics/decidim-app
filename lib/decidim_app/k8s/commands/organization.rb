# frozen_string_literal: true

require "decidim_app/k8s/manager"

module DecidimApp
  module K8s
    module Commands
      class Organization < Rectify::Command
        attr_accessor :status

        def initialize(organization, default_admin)
          @organization = organization
          @default_admin_name = default_admin[:name]
          @default_admin_email = default_admin[:email]
          @status = {}
          @topic = :organization
        end

        def call
          if existing_organization
            update
          else
            install
          end

          return broadcast(:invalid, @status, nil) if @status.any? { |_, status| status[:status] != :ok }

          broadcast(:ok, @status, existing_organization.reload)
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
              register_status(:create, :ok)
              update
            end

            on(:invalid) do
              register_status(:create, :invalid, form.tap(&:valid?).errors.messages)
            end
          end
        end

        def update
          form = Decidim::System::UpdateOrganizationForm.from_params(update_params)

          Decidim::System::UpdateOrganization.call(existing_organization.id, form) do
            on(:ok) do
              register_status(:update, :ok)
            end

            on(:invalid) do
              register_status(:update, :invalid, form.tap(&:valid?).errors.messages)
            end
          end
        end

        def register_status(action, status, messages = [])
          @status.deep_merge!(@topic => { action => { status: status, messages: messages }})
        end

        def existing_organization
          Decidim::Organization.find_by(name: @organization[:name]) || Decidim::Organization.find_by(host: @organization[:host])
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
