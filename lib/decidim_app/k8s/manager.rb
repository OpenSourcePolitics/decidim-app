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

      def self.logger
        @logger ||= LoggerWithStdout.new("log/decidim-app-k8s.log")
      end

      def run
        raise "Invalid configuration: #{@configuration.errors}" unless @configuration.valid?

        Commands::SystemAdmin.run(@configuration.system_admin)
        @configuration.organizations.each do |organization|
           Commands::Organization.call(organization, @configuration.default_admin) do
            on(:ok, status, organization) do
              Commands::Admin.run(@configuration.default_admin, organization)
            end
            on(:invalid, status) do
              puts "invalid state"
            end
          end
        end
      end
    end
  end
end
