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

        # create_system_admin
        @configuration.organizations.each do |organization|
          Commands::Organization.run(organization, @configuration.default_admin)
        end
        # install_default_admin
      end
    end
  end
end
