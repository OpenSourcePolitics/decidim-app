# frozen_string_literal: true

require "yaml"

require "decidim-app/k8s/configuration"
require "decidim-app/k8s/commands/organization"

module DecidimApp
  module K8s
    class Manager
      def initialize(path)
        @configuration = Configuration.new(YAML.safe_load(File.read(path)))
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
          organization = Commands::Organization.run(organization, @configuration.default_admin)
          Commands::Admin.run(@configuration.system_admin, organization)
        end

      end
    end
  end
end
