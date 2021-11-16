# frozen_string_literal: true

require "fog/aws"
require "digest"

module Decidim
  class S3RetentionService
    include Decidim::BackupHelper

    def self.run(options = {})
      new(options).execute
    end

    def initialize(options)
      @options = default_options.merge(options)
    end

    def default_options
      {
        s3_region: Rails.application.config.backup.dig(:s3sync, :region),
        s3_endpoint: Rails.application.config.backup.dig(:s3sync, :endpoint),
        s3_bucket: Rails.application.config.backup.dig(:s3sync, :bucket),
        s3_access_key: Rails.application.config.backup.dig(:s3sync, :access_key),
        s3_secret_key: Rails.application.config.backup.dig(:s3sync, :secret_key),
        s3_subfolder: Rails.application.config.backup.dig(:s3sync, :subfolder),
        s3_timestamp_file: Rails.application.config.backup.dig(:s3sync, :timestamp_file)
      }
    end

    def subfolder
      @subfolder ||= @options[:subfolder].presence || generate_subfolder_name
    end

    # rubocop:disable Style/CombinableLoops
    def retention_dates
      retention_dates = [Time.zone.now.strftime("%Y-%m-%d")]
      (1..13).each do |i|
        retention_dates << i.days.ago.strftime("%Y-%m-%d")
      end
      (1..6).each do |i|
        retention_dates << i.weeks.ago.strftime("%Y-%m-%d")
      end
      (1..6).each do |i|
        retention_dates << i.months.ago.strftime("%Y-%m-%d")
      end
      retention_dates << 1.year.ago.strftime("%Y-%m-%d")
      retention_dates.uniq
    end
    # rubocop:enable Style/CombinableLoops

    def execute
      directory = service.directories.get(@options[:s3_bucket], prefix: subfolder)

      directory.files.all.each do |file|
        next if file.key.end_with?(@options[:s3_timestamp_file])

        date_tag = service.get_object_tagging(@options[:s3_bucket], file.key).data.dig(:body, "ObjectTagging", "date")
        unless retention_dates.include?(date_tag)
          Rails.logger.info "Destroying file #{file.key} with date tag #{date_tag}"
          file.destroy
        end
      end
    end

    private

    def service
      @service ||= Fog::Storage.new(
        provider: "AWS",
        aws_access_key_id: @options[:s3_access_key],
        aws_secret_access_key: @options[:s3_secret_key],
        region: @options[:s3_region],
        endpoint: @options[:s3_endpoint],
        aws_signature_version: 4,
        enable_signature_v4_streaming: false
      )
    end
  end
end
