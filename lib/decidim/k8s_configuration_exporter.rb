# frozen_string_literal: true

class K8SConfigurationExporter
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

  def initialize(image, enable_sync)
    @image = image
    @enable_sync = enable_sync
    @organizations = Decidim::Organization.all
    @export_path = "tmp/k8s-migration"
    @logger = LoggerWithStdout.new("log/#{hostname}-k8s-export-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
    @hostname = `hostname`.strip.parameterize
    @database_name = Rails.configuration.database_configuration[Rails.env]["database"]
  end

  def self.export!(image, enable_sync)
    new(image, enable_sync).export!
  end

  def export!
    clean_migration_directory

    @logger.info "found #{@organizations.count} organization#{"s" if @organizations.count.positive?}"
    @logger.info "-------------------------"
    @organizations.find_each do |organization|
      @logger.info "exporting organization with host #{organization.host}"
      organization_slug = organization.host.parameterize(separator: "_", preserve_case: true)
      resource_name = "#{@hostname}--#{organization_slug}"
      organization_export_path = "#{@export_path}/#{resource_name}"

      creating_directories(organization_export_path, resource_name)
      exporting_env_vars(organization, organization_export_path, resource_name)
      exporting_configuration(organization, organization_export_path)
      dumping_database(organization_export_path, resource_name)
      retrieve_active_storage_files(env_vars, organization_export_path, resource_name)
    end

    perform_sync
  end

  def clean_migration_directory
    logger.info "cleaning migration directory #{@export_path}"
    system("rm -rf #{@export_path}")
    logger.info "creating migration directory #{@export_path}"
    system("mkdir -p #{@export_path}")
  end

  def perform_sync
    if @enable_sync
      @logger.info "cleaninf bucket #{@hostname}-migration"
      system("rclone delete scw-migration:#{@hostname}-migration --rmdirs --config ../scaleway.config")
      @logger.info "syncing export to bucket #{@hostname}-migration"
      system("rclone copy #{@export_path} scw-migration:#{@hostname}-migration --config ../scaleway.config --progress --copy-links")
    else
      @logger.info "NOT syncing export to bucket #{@hostname}-migration because ENABLE_SYNC is missing or false"
    end
  end

  def organization_settings(resource_name, host, secondary_hosts, org_columns_json, time_zone)
    {
      apiVersion: "apps.libre.sh/v1alpha1",
      kind: "Decidim",
      metadata: {
        name: resource_name
      },
      spec: {
        image: @image,
        host: host,
        additionalHosts: secondary_hosts,
        organization: org_columns_json,
        timeZone: time_zone,
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

  def organization_columns(organization)
    # TODO: Understand why JSON is used in this case
    org_columns_sql = "SELECT row_to_json(o,true) FROM (SELECT #{@organization_columns} FROM decidim_@organizations WHERE id=#{organization.id}) AS o;"
    org_columns_record = ActiveRecord::Base.connection.execute(org_columns_sql)
    JSON.parse(org_columns_record.first["row_to_json"])
  end

  def env_vars
    @env_vars ||= Dotenv.parse(".env")
                        .reject! { |key, _value| @forbidden_environment_keys.include?(key) }
  end

  def exporting_env_vars(organization, path, resource_name)
    @logger.info "exporting env variables to #{path}/manifests/#{resource_name}--de.yml"
    File.write("#{path}/manifests/#{resource_name}-config.yml",
               YAML.dump(env_vars.merge!(smtp_settings(organization)).merge!(omniauth_settings(organization))))
  end

  def omniauth_settings(organization)
    organization.omniauth_settings.map do |key, value|
      value = Decidim::AttributeEncryptor.decrypt(value) if Decidim::OmniauthProvider.value_defined?(value)
      [key.upcase, value]
    end.to_h
  end

  def smtp_settings(organization)
    settings = organization.smtp_settings.deep_dup
    settings["password"] = Decidim::AttributeEncryptor.decrypt(settings["encrypted_password"])
    settings.delete("encrypted_password")

    settings.transform_keys do |key|
      "SMTP_#{key.upcase}"
    end
  end

  def exporting_configuration(organization, path)
    @logger.info "exporting application configuration to #{path}/application.yml"
    organization_settings = organization_settings(resource_name, organization.host, organization.secondary_hosts, organization_columns(organization), organization.time_zone)
    File.write("#{path}/application.yml", YAML.dump(organization_settings))
  end

  def dumping_database(path, resource_name)
    @logger.info "dumping database #{@database_name} to #{path}/postgres/#{resource_name}--de.dump"
    system("pg_dump -Fc #{@database_name} > #{path}/postgres/#{resource_name}--de.dump")
  end

  def creating_directories(path, resource_name)
    @logger.info "creating organization directories"
    @logger.info "#{path}/buckets/#{resource_name}--de"
    system("mkdir -p #{path}/buckets/#{resource_name}--de")
    @logger.info "#{path}/manifests"
    system("mkdir -p #{path}/manifests")
    @logger.info "#{path}/postgres"
    system("mkdir -p #{path}/postgres")
  end

  def retrieve_active_storage_files(env_vars, path, resource_name)
    @logger.info "retrieving active storage files from bucket #{env_vars["SCALEWAY_BUCKET_NAME"]} into #{path}/buckets/#{resource_name}--de"
    system("rclone copy scw-storage:#{env_vars["SCALEWAY_BUCKET_NAME"]} #{path}/buckets/#{resource_name}--de --config ../scaleway.config --progress --copy-links")
  end
end
