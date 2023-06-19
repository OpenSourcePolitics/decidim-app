# frozen_string_literal: true

require "logger_with_stdout"
require "k8s_organization_exporter"

class K8sConfigurationExporter
  EXPORT_PATH = Rails.root.join("tmp/k8s-migration")

  def initialize(image, enable_sync)
    @image = image
    @enable_sync = enable_sync
    @organizations = Decidim::Organization.all
    @logger = LoggerWithStdout.new("log/#{hostname}-k8s-export-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
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
      K8sOrganizationExporter.export!(organization, @logger, EXPORT_PATH, hostname, @image)
    end

    perform_sync
  end

  def clean_migration_directory
    @logger.info("cleaning migration directory #{EXPORT_PATH}")
    FileUtils.rm_rf(EXPORT_PATH)
    @logger.info("creating migration directory #{EXPORT_PATH}")
    FileUtils.mkdir_p(EXPORT_PATH)
  end

  def perform_sync
    if @enable_sync
      @logger.info("Cleaning bucket #{@hostname}-migration")
      system("rclone delete scw-migration:#{@hostname}-migration --rmdirs --config ../scaleway.config")
      @logger.info("Syncing export to bucket #{@hostname}-migration")
      system("rclone copy #{EXPORT_PATH} scw-migration:#{@hostname}-migration --config ../scaleway.config --progress --copy-links")
    else
      @logger.info("NOT syncing export to bucket #{@hostname}-migration because ENABLE_SYNC is missing or false")
      true
    end
  end

  def hostname
    # Socket.gethostname returns a string with ASCII-8BIT encoding, which is not compatible with parameterize
    # We need to force the encoding to UTF-8 before calling parameterize on it
    # We need to dup the string because force_encoding returns a new string and the original is frozen
    @hostname ||= Socket.gethostname
                        .dup
                        .force_encoding("UTF-8")
                        .parameterize
  end
end
