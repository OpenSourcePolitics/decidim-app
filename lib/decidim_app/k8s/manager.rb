# frozen_string_literal: true

require "yaml"

require "decidim_app/k8s/configuration"
require "decidim_app/k8s/commands/organization"
require "decidim_app/k8s/commands/system_admin"
require "decidim_app/k8s/commands/admin"

module DecidimApp
  module K8s
    class Manager
      def initialize(path)
        @configuration = Configuration.new(path)
      end

      def self.run(path)
        new(path).run
      end

      def run
        raise "Invalid configuration: #{@configuration.errors}" unless @configuration.valid?

        Commands::SystemAdmin.call(@configuration.system_admin) do
          on(:ok) do |status_registry|
            log_status(status_registry)

            create_or_update_organizations
          end

          on(:invalid) do |status_registry|
            log_status(status_registry)

            raise "Invalid system admin, #{status_registry["messages"]}"
          end
        end
      end

      def create_or_update_organizations
        @configuration.organizations.each do |organization_configuration|
          Commands::Organization.call(organization_configuration, @configuration.default_admin) do
            on(:ok) do |status_registry, existing_organization|
              log_status(status_registry)

              create_or_update_admins(existing_organization)
            end

            on(:invalid) do |status_registry|
              log_status(status_registry)

              raise "Invalid organization, #{status_registry["messages"]}"
            end
          end
        end
      end

      def create_or_update_admins(organization)
        Commands::Admin.call(@configuration.default_admin, organization) do
          on(:ok) do |status_registry|
            log_status(status_registry)
          end

          on(:invalid) do |status_registry|
            log_status(status_registry)

            raise "Invalid admin, #{status_registry["messages"]}"
          end
        end
      end

      def logger
        @logger ||= LoggerWithStdout.new("log/decidim-app-k8s.log")
      end

      def log_status(status_registry)
        status_registry.each do |topic, status|
          status.each do |action, messages|
            message = "#{topic.to_s.capitalize} has been #{action} with status #{messages[:status]}"
            message += " #{messages[:messages]}" unless messages[:messages].empty?

            logger.send((messages[:status] == :ok ? :info : :error), message)
          end
        end
      end
    end
  end
end
