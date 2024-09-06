# frozen_string_literal: true

require "logger_with_stdout"
require "decidim_app/k8s/organization_exporter"

module DecidimApp
  module K8s
    class ConfigurationExporter
      EXPORT_PATH = Rails.root.join("tmp/k8s-migration")

      def initialize(image = "")
        @image = image
        @organizations = Decidim::Organization.all
        @logger = ::LoggerWithStdout.new("log/k8s-export-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      end

      def self.dump_db
        new.dump_db
      end

      def dump_db
        @logger.info("found #{@organizations.count} organization#{"s" if @organizations.count.positive?}")
        @logger.info("-------------------------")
        @organizations.find_each do |organization|
          @logger.info("Dumping database organization with host #{organization.host}")
          K8s::OrganizationExporter.dumping_database(organization, @logger, EXPORT_PATH)
        end
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
          K8s::OrganizationExporter.export!(organization, @logger, EXPORT_PATH, @image)
        end
      end

      def clean_migration_directory
        @logger.info("cleaning migration directory #{EXPORT_PATH}")
        FileUtils.rm_rf(EXPORT_PATH)
        @logger.info("creating migration directory #{EXPORT_PATH}")
        FileUtils.mkdir_p(EXPORT_PATH)
      end
    end
  end
end
