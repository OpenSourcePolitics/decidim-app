# frozen_string_literal: true

require "logger_with_stdout"
require "k8s_organization_exporter"

class K8SConfigurationExporter
  def initialize(image, enable_sync)
    @image = image
    @enable_sync = enable_sync
    @organizations = Decidim::Organization.all
    @export_path = "tmp/k8s-migration"
    @logger = LoggerWithStdout.new("log/#{hostname}-k8s-export-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
    @database_name = Rails.configuration.database_configuration[Rails.env]["database"]
  end

  def self.export!(image, enable_sync)
    new(image, enable_sync).export!
  end

  def export!
    clean_migration_directory

    @logger.info("found #{@organizations.count} organization#{"s" if @organizations.count.positive?}")
    @logger.info("-------------------------")
    @organizations.find_each do |organization|
      @logger.info("exporting organization with host #{organization.host}")
      K8SOrganizationExporter.export!(organization, @logger, @export_path, hostname)
    end

    perform_sync
  end

  def clean_migration_directory
    @logger.info("cleaning migration directory #{@export_path}")
    FileUtils.rm_rf(@export_path)
    @logger.info("creating migration directory #{@export_path}")
    FileUtils.mkdir_p(@export_path)
  end

  def perform_sync
    if @enable_sync
      @logger.info("Cleaning bucket #{@hostname}-migration")
      system("rclone delete scw-migration:#{@hostname}-migration --rmdirs --config ../scaleway.config")
      @logger.info("Syncing export to bucket #{@hostname}-migration")
      system("rclone copy #{@export_path} scw-migration:#{@hostname}-migration --config ../scaleway.config --progress --copy-links")
    else
      @logger.info("NOT syncing export to bucket #{@hostname}-migration because ENABLE_SYNC is missing or false")
      true
    end
  end

  def hostname
    @hostname ||= `hostname`.strip.parameterize
  end
end
