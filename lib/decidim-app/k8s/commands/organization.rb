# frozen_string_literal: true

module DecidimApp
  module K8s
    module Commands
      class Organization
        def self.run(configuration, default_admin_configuration)
          new(configuration, default_admin_configuration).run
        end

        def initialize(configuration, default_admin_configuration)
          @configuration = configuration
          @default_admin_email = default_admin_configuration["name"]
          @default_admin_name = default_admin_configuration["email"]
        end

        def run
          K8s::Manager.logger.info("Installing organization : '#{@configuration["name"]}'")

          if existing_organization
            K8s::Manager.logger.info("Organization #{organization} already exist")
            install
          else
            update(existing_organization)
          end
        end

        def install
          form = form(RegisterOrganizationForm).from_params(
            @configuration.merge(
              "organization_admin_email" => @default_admin_email,
              "organization_admin_name" => @default_admin_name
            )
          )

          RegisterOrganization.call(form) do
            on(:ok) do
              K8s::Manager.logger.info("Organization #{organization} created")
              update(existing_organization)
            end

            on(:invalid) do
              K8s::Manager.logger.info("Organization #{organization} could not be created")
              form.errors.full_messages.each do |error|
                K8s::Manager.logger.info(error)
              end
            end
          end
        end

        def update(existing_organization)
          form = form(UpdateOrganizationForm).from_params(@configuration)

          UpdateOrganization.call(existing_organization.id, form) do
            on(:ok) do
              K8s::Manager.logger.info("Organization #{@configuration["name"]} updated")
            end

            on(:invalid) do
              K8s::Manager.logger.info("Organization #{@configuration["name"]} could not be updated")
              form.errors.full_messages.each do |error|
                K8s::Manager.logger.info(error)
              end
            end
          end
        end

        def existing_organization
          Decidim::Organization.find_by(name: @configuration["name"]) || Decidim::Organization.find_by(host: @configuration["host"])
        end
      end
    end
  end
end
