# frozen_string_literal: true

require "uri"
require "net/http"
require "decidim_app/k8s/secondary_hosts_checker"

module DecidimApp
  module K8s
    class OrganizationExporter
      FORBIDDEN_ENVIRONMENT_KEYS = %w(BACKUP_ENABLED
                                      BACKUP_S3SYNC_ENABLED
                                      BACKUP_S3SYNC_ACCESS_KEY
                                      BACKUP_S3SYNC_SECRET_KEY
                                      BACKUP_S3SYNC_BUCKET
                                      BACKUP_S3RETENTION_ENABLED
                                      DEFAULT_LOCALE
                                      AVAILABLE_LOCALES
                                      FORCE_SSL
                                      SCALEWAY_ID
                                      SCALEWAY_TOKEN
                                      SCALEWAY_BUCKET_NAME
                                      SECRET_KEY_BASE
                                      ENABLE_RACK_ATTACK).freeze

      DEFAULT_ENVIRONMENT_VARIABLES = {
        "ENABLE_RACK_ATTACK" => 0
      }.freeze

      ORGANIZATION_COLUMNS = %w(id
                                default_locale
                                available_locales
                                users_registration_mode
                                force_users_to_authenticate_before_access_organization
                                available_authorizations
                                file_upload_settings).freeze

      def initialize(organization, logger, export_path, image = "")
        @organization = organization
        @logger = logger
        @export_path = export_path
        @image = image
        @database_name = Rails.configuration.database_configuration[Rails.env]["database"]
      end

      def self.export!(organization, logger, export_path, image)
        new(organization, logger, export_path, image).export!
      end

      def self.dumping_database(organization, logger, export_path)
        new(organization, logger, export_path).dumping_database
      end

      def export!
        creating_directories
        exporting_env_vars
        exporting_configuration
      end

      def dumping_database
        @logger.info("dumping database #{@database_name} to #{organization_export_path}/postgres/#{resource_name}--de.dump")
        system("pg_dump -Fc #{@database_name} > #{organization_export_path}/postgres/#{resource_name}--de.dump")
      end

      def exporting_configuration
        @logger.info("exporting application configuration to #{organization_export_path}/application.yml")
        File.write("#{organization_export_path}/application.yml", YAML.dump(organization_settings))
      end

      def exporting_env_vars
        @logger.info("exporting env variables to #{organization_export_path}/manifests/#{resource_name}-custom-env.yml")
        File.write("#{organization_export_path}/manifests/#{resource_name}-custom-env.yml",
                   YAML.dump(all_env_vars))
        @logger.info("exporting env variables to #{organization_export_path}/manifests/#{resource_name}--de.yml")
        File.write("#{organization_export_path}/manifests/#{resource_name}--de.yml",
                   YAML.dump(secret_key_base_env_var))
      end

      def creating_directories
        @logger.info("creating organization directories")
        @logger.info("#{organization_export_path}/manifests")
        FileUtils.mkdir_p("#{organization_export_path}/manifests")
        @logger.info("#{organization_export_path}/postgres")
        FileUtils.mkdir_p("#{organization_export_path}/postgres")
      end

      def all_env_vars
        {
          apiVersion: "v1",
          kind: "Secret",
          metadata: {
            name: "#{resource_name}-custom-env"
          },
          stringData: env_vars.merge(smtp_settings).merge(omniauth_settings)
        }.deep_stringify_keys
      end

      def env_vars
        @env_vars ||= Dotenv.parse(".env")
                            .reject { |key, _value| FORBIDDEN_ENVIRONMENT_KEYS.include?(key) }
                            .merge(DEFAULT_ENVIRONMENT_VARIABLES)
                            .transform_values(&:to_s)
      end

      def secret_key_base_env_var
        {
          apiVersion: "v1",
          kind: "Secret",
          metadata: {
            name: "#{resource_name}--de"
          },
          stringData: {
            SECRET_KEY_BASE: (Dotenv.parse(".env")["SECRET_KEY_BASE"]).to_s
          }
        }.deep_stringify_keys
      end

      def omniauth_settings
        return {} unless @organization.omniauth_settings

        settings = @organization.omniauth_settings
                                .deep_dup
                                .each_with_object({}) do |(key, value), hash|
          hash[key.upcase] = Decidim::OmniauthProvider.value_defined?(value) ? decrypt(value) : value
        end

        settings.deep_transform_values(&:to_s)
      end

      def smtp_settings
        settings = @organization.smtp_settings.deep_dup || {}
        settings["password"] = settings["encrypted_password"] ? Decidim::AttributeEncryptor.decrypt(settings["encrypted_password"]) : nil
        settings.delete("encrypted_password")

        settings = settings.transform_keys do |key|
          "SMTP_#{key.upcase}"
        end

        settings.deep_transform_values(&:to_s)
      end

      def organization_columns
        org_columns_sql = "SELECT row_to_json(o,true) FROM (SELECT #{ORGANIZATION_COLUMNS.join(", ")} FROM decidim_organizations WHERE id=#{@organization.id}) AS o;"
        org_columns_record = ActiveRecord::Base.connection.execute(org_columns_sql)
        JSON.parse(org_columns_record.first["row_to_json"])
      end

      def organization_settings
        {
          apiVersion: "apps.libre.sh/v1alpha1",
          kind: "Decidim",
          metadata: {
            name: resource_name,
            namespace: name_space
          },
          spec: {
            image: @image,
            host: @organization.host,
            additionalHosts: DecidimApp::K8s::SecondaryHostsChecker.valid_secondary_hosts(host: @organization.host, secondary_hosts: @organization.secondary_hosts),
            organization: { id: organization_columns["id"] },
            locale: {
              default: organization_columns["default_locale"],
              available: organization_columns["available_locales"]
            },
            usersRegistrationMode: organization_columns["users_registration_mode"],
            forceUsersToAuthenticateBeforeAccessOrganization: organization_columns["force_users_to_authenticate_before_access_organization"],
            availableAuthorizations: organization_columns["available_authorizations"],
            fileUploadSettings: organization_columns["file_upload_settings"],
            timeZone: @organization.time_zone,
            envFrom: [
              {
                secretRef: {
                  name: "#{resource_name}-custom-env"
                }
              }
            ]
          }
        }.deep_stringify_keys
      end

      def organization_export_path
        @organization_export_path ||= "#{@export_path}/#{name_space}--#{resource_name}"
      end

      def resource_name
        @resource_name ||= @organization.host.split(".").first
      end

      def name_space
        @name_space ||= @organization.host.split(".", 2).last.gsub(".", "-")
      end

      private

      def decrypt(value)
        Decidim::AttributeEncryptor.decrypt(value)
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        value
      end
    end
  end
end
