# frozen_string_literal: true

require "decidim_app/k8s/manager"

module DecidimApp
  module K8s
    module Commands
      class Organization
        def self.run(configuration, default_admin_configuration)
          new(configuration, default_admin_configuration).run
        end

        def initialize(configuration, default_admin_configuration)
          @configuration = configuration
          @default_admin_name = default_admin_configuration[:name]
          @default_admin_email = default_admin_configuration[:email]
        end

        def run
          if existing_organization
            K8s::Manager.logger.info("Organization #{@configuration[:name]} already exist")

            update
          else
            K8s::Manager.logger.info("Installing organization : '#{@configuration[:name]}'")

            install
          end
        end

        def install
          form = Decidim::System::RegisterOrganizationForm.from_params(
            @configuration.merge(
              organization_admin_email: @default_admin_email,
              organization_admin_name: @default_admin_name
            )
          )

          Decidim::System::RegisterOrganization.call(form) do
            on(:ok) do
              K8s::Manager.logger.info("Organization #{form.name} created")
              update
            end

            on(:invalid) do
              K8s::Manager.logger.info("Organization #{form.name} could not be created")
              form.tap(&:valid?).errors.messages.each do |error|
                K8s::Manager.logger.info(error)
              end

              raise "Organization #{form.name} could not be created"
            end
          end

          existing_organization
        end

        def update
          form = Decidim::System::UpdateOrganizationForm.from_params(update_params)

          Decidim::System::UpdateOrganization.call(existing_organization.id, form) do
            on(:ok) do
              K8s::Manager.logger.info("Organization #{form.name} updated")
            end

            on(:invalid) do
              K8s::Manager.logger.info("Organization #{form.name} could not be updated")
              form.tap(&:valid?).errors.messages.each do |error|
                K8s::Manager.logger.info(error)
              end

              raise "Organization #{form.name} could not be updated"
            end
          end

          existing_organization.reload
        end

        def existing_organization
          Decidim::Organization.find_by(name: @configuration[:name]) || Decidim::Organization.find_by(host: @configuration[:host])
        end

        def existing_organization_attributes
          Decidim::System::UpdateOrganizationForm.from_model(existing_organization).attributes_with_values.deep_symbolize_keys
        end

        def update_params
          params = existing_organization_attributes.deep_merge(
            @configuration.except(:smtp_settings, :omniauth_settings)
          ).merge(id: existing_organization.id)

          @configuration.fetch(:smtp_settings, {}).each do |key, value|
            params.merge!(key => value)
          end

          @configuration.fetch(:omniauth_settings, {}).each do |provider, config|
            config.each do |key, value|
              params.merge!("omniauth_settings_#{provider}_#{key}" => value)
            end
          end

          params[:encrypted_password] = nil if @configuration.dig(:smtp_settings, :password).present?

          params
        end
      end
    end
  end
end
