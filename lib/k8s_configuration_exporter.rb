# frozen_string_literal: true

require "logger_with_stdout"
require "k8s_organization_exporter"

class K8sConfigurationExporter
  EXPORT_PATH = Rails.root.join("tmp/k8s-migration")

  def initialize(image)
    @image = image
    @organizations = Decidim::Organization.all
    @logger = LoggerWithStdout.new("log/#{hostname}-k8s-export-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
  end

  def self.export!(image)
    new(image).export!
  end

  def export!
    clean_migration_directory

    @logger.info("found #{@organizations.count} organization#{"s" if @organizations.count.positive?}")
    @logger.info("-------------------------")
    @organizations.find_each do |organization|
      @logger.info("exporting organization with host #{organization.host}")
      K8sOrganizationExporter.export!(organization, @logger, EXPORT_PATH, hostname, @image)
    end
  end

  def clean_migration_directory
    @logger.info("cleaning migration directory #{EXPORT_PATH}")
    FileUtils.rm_rf(EXPORT_PATH)
    @logger.info("creating migration directory #{EXPORT_PATH}")
    FileUtils.mkdir_p(EXPORT_PATH)
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
