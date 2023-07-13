# frozen_string_literal: true

module DecidimApp
  module K8s
    class Configuration
      attr_reader :organizations, :system_admin, :default_admin

      TRANSFORMS_METHODS = {
        to_string_separated_by_new_line: ->(value) { value.join("\n") },
        to_string_separated_by_comma: ->(value) { value.join(",") }
      }.freeze

      TRANSFORMS = {
        secondary_hosts: :to_string_separated_by_new_line,
        file_upload_settings_allowed_file_extensions_admin: :to_string_separated_by_comma,
        file_upload_settings_allowed_file_extensions_image: :to_string_separated_by_comma,
        file_upload_settings_allowed_file_extensions_default: :to_string_separated_by_comma,
        file_upload_settings_allowed_content_types_admin: :to_string_separated_by_comma,
        file_upload_settings_allowed_content_types_default: :to_string_separated_by_comma
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

        organizations&.map { |organization| deep_transform(organization) } || []
      end

      # Transforms the keys based on the TRANSFORMS present
      # Return a new hash with the transformed keys
      # Example:
      # To match against { file_upload_settings: { allowed_file_extensions: { admin } } }
      # file_upload_settings_allowed_file_extensions_admin: ->(value) { value.join(",") }
      def deep_transform(hash, prefix = "")
        hash.each_with_object({}) do |(key, value), new_hash|
          match_key = prefix.present? ? "#{prefix}_#{key}".to_sym : key

          new_hash[key] = if value.is_a?(Hash)
                            deep_transform(value, match_key)
                          else
                            transform(match_key, value)
                          end
        end
      end

      def transform(match_key, value)
        return value unless TRANSFORMS[match_key]

        TRANSFORMS_METHODS[TRANSFORMS[match_key]].call(value)
      end
    end
  end
end
