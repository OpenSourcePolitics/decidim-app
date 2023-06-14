# frozen_string_literal: true

namespace :decidim do
  namespace :k8s do
    desc "usage: bundle exec rails decidim:k8s:export_configuration IMAGE=<docker_image_ref> [ENABLE_SYNC=true]"
    task export_configuration: :environment do
      hostname = `hostname`.strip.parameterize
      export_path = "tmp/k8s-migration"

      logger = LoggerWithStdout.new("log/#{hostname}-k8s-export-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")

      docker_image = ENV["IMAGE"]

      if docker_image.blank?
        logger.fatal "You must specify a docker image"
        logger.fatal "usage: bundle exec rails decidim:k8s:export_configuration IMAGE=<docker_image_ref> [ENABLE_SYNC=true]"
        exit 1
      end

      logger.info "cleaning migration directory #{export_path}"
      system("rm -rf #{export_path}")
      logger.info "creating migration directory #{export_path}"
      system("mkdir -p #{export_path}")

      organizations = Decidim::Organization.all

      logger.info "found #{organizations.count} organization#{"s" if organizations.count.positive?}"
      logger.info "-------------------------"
      organizations.each do |org|
        logger.info "exporting organization with host #{org.host}"

        org_slug = org.host.parameterize(separator: "_", preserve_case: true)
        ressource_name = "#{hostname}--#{org_slug}"
        org_export_path = "#{export_path}/#{ressource_name}"

        logger.info "creating organization directories"
        logger.info "#{org_export_path}/buckets/#{ressource_name}--de"
        system("mkdir -p #{org_export_path}/buckets/#{ressource_name}--de")
        logger.info "#{org_export_path}/manifests"
        system("mkdir -p #{org_export_path}/manifests")
        logger.info "#{org_export_path}/postgres"
        system("mkdir -p #{org_export_path}/postgres")

        logger.info "decoding SMTP settings"
        smtp_settings = org.smtp_settings
        smtp_settings["password"] = Decidim::AttributeEncryptor.decrypt(org.smtp_settings["encrypted_password"])
        smtp_settings.delete("encrypted_password")

        smtp_settings = smtp_settings.transform_keys do |key|
          "SMTP_#{key.upcase}"
        end

        logger.info "decoding Omniauth settings"
        omniauth_settings = org.omniauth_settings.map do |key, value|
          value = Decidim::AttributeEncryptor.decrypt(value) if Decidim::OmniauthProvider.value_defined?(value)
          [key.upcase, value]
        end.to_h

        logger.info "exporting ENV variables to #{org_export_path}/manifests/#{ressource_name}--de.yml"
        env_vars = Dotenv.parse(".env")
        env_vars.reject! do |key, _value|
          %w(
            BACKUP_ENABLED
            BACKUP_S3SYNC_ENABLED
            BACKUP_S3SYNC_ACCESS_KEY
            BACKUP_S3SYNC_SECRET_KEY
            BACKUP_S3SYNC_BUCKET
            BACKUP_S3RETENTION_ENABLED
          ).include?(key)
        end
        env_vars.merge!(smtp_settings)
        env_vars.merge!(omniauth_settings)

        env_vars_yaml = YAML.dump(env_vars)
        File.open("#{org_export_path}/manifests/#{ressource_name}-config.yml", "w") { |e| e.write(env_vars_yaml) }

        logger.info "exporting application configuration to #{org_export_path}/application.yml"

        # getting organization data in raw format
        org_columns = %w(
          id
          default_locale
          available_locales
          users_registration_mode
          force_users_to_authenticate_before_access_organization
          available_authorizations
          file_upload_settings
        )
        org_columns_sql = "SELECT row_to_json(o,true) FROM (SELECT #{org_columns.join(", ")} FROM decidim_organizations WHERE id=#{org.id}) AS o;"
        org_columns_record = ActiveRecord::Base.connection.execute(org_columns_sql)
        org_columns_json = JSON.parse(org_columns_record.first["row_to_json"])

        org_settings = {
          apiVersion: "apps.libre.sh/v1alpha1",
          kind: "Decidim",
          metadata: {
            name: ressource_name
          },
          spec: {
            image: docker_image,
            host: org.host,
            additionalHosts: org.secondary_hosts,
            organization: org_columns_json,
            timeZone: org.time_zone,
            envFrom: [
              {
                secretRef: {
                  name: "#{ressource_name}-config"
                }
              }
            ]
          }
        }

        org_settings_yaml = YAML.dump(org_settings.deep_stringify_keys)
        File.open("#{org_export_path}/application.yml", "w") { |e| e.write(org_settings_yaml) }

        database_name = Rails.configuration.database_configuration[Rails.env]["database"]
        logger.info "dumping database #{database_name} to #{org_export_path}/postgres/#{ressource_name}--de.dump"
        system("pg_dump -Fc #{database_name} > #{org_export_path}/postgres/#{ressource_name}--de.dump")

        logger.info "retrieving active storage files from bucket #{env_vars["SCALEWAY_BUCKET_NAME"]} into #{org_export_path}/buckets/#{ressource_name}--de"
        system("rclone copy scw-storage:#{env_vars["SCALEWAY_BUCKET_NAME"]} #{org_export_path}/buckets/#{ressource_name}--de --config ../scaleway.config --progress --copy-links")
      end
      # end of organizations.each

      enable_sync = ENV["ENABLE_SYNC"].to_s == "true"
      if enable_sync
        logger.info "cleaninf bucket #{hostname}-migration"
        system("rclone delete scw-migration:#{hostname}-migration --rmdirs --config ../scaleway.config")
        logger.info "syncing export to bucket #{hostname}-migration"
        system("rclone copy #{export_path} scw-migration:#{hostname}-migration --config ../scaleway.config --progress --copy-links")
      else
        logger.info "NOT syncing export to bucket #{hostname}-migration because ENABLE_SYNC is missing or false"
      end
    end
  end
end
