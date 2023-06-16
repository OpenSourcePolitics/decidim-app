# frozen_string_literal: true

class K8SOrganizationExporter
  FORBIDDEN_ENVIRONMENT_KEYS = %w(BACKUP_ENABLED
                                  BACKUP_S3SYNC_ENABLED
                                  BACKUP_S3SYNC_ACCESS_KEY
                                  BACKUP_S3SYNC_SECRET_KEY
                                  BACKUP_S3SYNC_BUCKET
                                  BACKUP_S3RETENTION_ENABLED).freeze
  ORGANIZATION_COLUMNS = %w(id
                            default_locale
                            available_locales
                            users_registration_mode
                            force_users_to_authenticate_before_access_organization
                            available_authorizations
                            file_upload_settings).join(", ").freeze

  def initialize(organization, logger, export_path, hostname)
    @organization = organization
    @logger = logger
    @export_path = export_path
    @hostname = hostname
  end

  def self.export!(organization, logger, export_path, hostname)
    new(organization, logger, export_path, hostname).export!
  end

  def export!
    creating_directories
    exporting_env_vars
    exporting_configuration
    dumping_database
    retrieve_active_storage_files
  end

  def retrieve_active_storage_files
    @logger.info("retrieving active storage files from bucket #{bucket_name} into #{organization_export_path}/buckets/#{resource_name}--de")
    system("rclone copy scw-storage:#{bucket_name} #{organization_export_path}/buckets/#{resource_name}--de --config ../scaleway.config --progress --copy-links")
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
    @logger.info("exporting env variables to #{organization_export_path}/manifests/#{resource_name}--de.yml")
    File.write("#{organization_export_path}/manifests/#{resource_name}-config.yml",
               YAML.dump(env_vars.merge!(smtp_settings).merge!(omniauth_settings)))
  end

  def creating_directories
    @logger.info("creating organization directories")
    @logger.info("#{organization_export_path}/buckets/#{resource_name}--de")
    FileUtils.mkdir_p("#{organization_export_path}/buckets/#{resource_name}--de")
    @logger.info("#{organization_export_path}/manifests")
    FileUtils.mkdir_p("#{organization_export_path}/manifests")
    @logger.info("#{organization_export_path}/postgres")
    FileUtils.mkdir_p("#{organization_export_path}/postgres")
  end

  def env_vars
    @env_vars ||= Dotenv.parse(".env")
                        .reject! { |key, _value| FORBIDDEN_ENVIRONMENT_KEYS.include?(key) }
  end

  def omniauth_settings
    @organization.omniauth_settings.each_with_object({}) do |(key, value), hash|
      hash[key.upcase] = Decidim::OmniauthProvider.value_defined?(value) ? Decidim::AttributeEncryptor.decrypt(value) : nil
    end
  end

  def smtp_settings
    settings = @organization.smtp_settings.deep_dup
    settings["password"] = Decidim::AttributeEncryptor.decrypt(settings["encrypted_password"])
    settings.delete("encrypted_password")

    settings.transform_keys do |key|
      "SMTP_#{key.upcase}"
    end
  end

  def organization_columns
    # TODO: Understand why JSON is used in this case
    org_columns_sql = "SELECT row_to_json(o,true) FROM (SELECT #{ORGANIZATION_COLUMNS} FROM decidim_@organizations WHERE id=#{@organization.id}) AS o;"
    org_columns_record = ActiveRecord::Base.connection.execute(org_columns_sql)
    JSON.parse(org_columns_record.first["row_to_json"])
  end

  def organization_settings
    {
      apiVersion: "apps.libre.sh/v1alpha1",
      kind: "Decidim",
      metadata: {
        name: resource_name
      },
      spec: {
        image: @image,
        host: @organization.host,
        additionalHosts: @organization.secondary_hosts,
        organization: organization_columns,
        timeZone: @organization.time_zone,
        envFrom: [
          {
            secretRef: {
              name: "#{resource_name}-config"
            }
          }
        ]
      }
    }.deep_stringify_keys
  end

  def organization_export_path
    @organization_export_path ||= "#{@export_path}/#{resource_name}"
  end

  def resource_name
    @resource_name ||= "#{@hostname}--#{@organization_slug}"
  end

  def bucket_name
    @bucket_name ||= env_vars["SCALEWAY_BUCKET_NAME"]
  end

  def organization_slug
    @organization_slug ||= @organization.host.parameterize(separator: "_", preserve_case: true)
  end
end
