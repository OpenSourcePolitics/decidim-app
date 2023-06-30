# frozen_string_literal: true

module DecidimApp
  module K8s
    class Configuration
      attr_reader :organizations, :system_admin, :default_admin

      def initialize(parsed_yaml)
        @organizations = parsed_yaml["organizations"].is_a?(Hash) ? [parsed_yaml["organizations"]] : parsed_yaml["organizations"]
        @system_admin = parsed_yaml["system_admin"]
        @default_admin = parsed_yaml["default_admin"]
      end

      def valid?
        instance_variables.none? do |variable|
          instance_variable_get(variable).nil?
        end
      end

      def errors
        return [] if valid?

        instance_variables.select { |variable| instance_variable_get(variable).nil? }
                          .map { |variable| "#{variable.to_s.gsub("@", "")} is required" }
                          .join(", ")
      end
    end
  end
end
