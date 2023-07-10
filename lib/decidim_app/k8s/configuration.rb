# frozen_string_literal: true

module DecidimApp
  module K8s
    class Configuration
      attr_reader :organizations, :system_admin, :default_admin

      TRANSFORMS = {
        secondary_hosts: ->(value) { value.join("\n") }
      }.freeze

      def initialize(path)
        @parsed_configuration = YAML.load_file(path).deep_symbolize_keys
        @organizations = set_organizations
        @system_admin = @parsed_configuration[:system_admin]
        @default_admin = @parsed_configuration[:default_admin]
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

      private

      def set_organizations
        organizations = @parsed_configuration[:organizations].is_a?(Hash) ? [@parsed_configuration[:organizations]] : @parsed_configuration[:organizations]

        organizations&.map do |organization|
          organization.each_with_object({}) do |(key, value), hash|
            hash[key] = TRANSFORMS[key] ? TRANSFORMS[key].call(value) : value
          end
        end
      end
    end
  end
end
