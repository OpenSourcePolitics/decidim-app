# frozen_string_literal: true

require "fog/aws"
require "digest"

module Decidim
  class S3SyncService
    def self.run(options = {})
      new(options).execute
    end

    def initialize(options)
      @options = default_options.merge(options)
    end

    def default_options
      {
        local_backup_dir: Rails.application.config.backup[:directory],
        s3_region: Rails.application.config.backup.dig(:s3sync, :region),
        s3_endpoint: Rails.application.config.backup.dig(:s3sync, :endpoint),
        s3_bucket: Rails.application.config.backup.dig(:s3sync, :bucket),
        s3_access_key: Rails.application.config.backup.dig(:s3sync, :access_key),
        s3_secret_key: Rails.application.config.backup.dig(:s3sync, :secret_key),
        s3_subfolder: Rails.application.config.backup.dig(:s3sync, :subfolder),
        s3_timestamp_file: Rails.application.config.backup.dig(:s3sync, :timestamp_file),
        s3_sync_enabled: Rails.application.config.backup.dig(:s3sync, :enabled)
      }
    end

    def has_local_backup_directory?
      File.directory?(@options[:local_backup_dir]) & File.readable?(@options[:local_backup_dir])
    end

    def generate_subfolder_name
      [
        `hostname`,
        File.basename(`git rev-parse --show-toplevel`),
        `git branch --show-current`
      ].map(&:parameterize).join("--")
    end

    def subfolder
      @subfolder ||= @options[:subfolder].presence || generate_subfolder_name
    end

    def force_upload?
      @force_upload ||= ARGV.include?("--force")
    end

    def timestamp
      @timestamp ||= Time.zone.now.strftime("%Y-%m-%d-%H%M%S")
    end

    def execute
      directory = service.directories.get("osp-backup-dev", prefix: subfolder)

      Dir.each_child(@options[:local_backup_dir]) do |filename|
        md5 = Digest::MD5.file("#{@options[:local_backup_dir]}/#{filename}").base64digest
        key = "#{subfolder}/#{filename}"

        old_file = directory.files.head(key: key)

        if old_file.nil? || force_upload? || old_file.content_md5 != md5
          file = directory.files.new(key: key, body: File.open("#{@options[:local_backup_dir]}/#{filename}"))
          file.multipart_chunk_size = 10 * 1024 * 1024
          file.concurrency = 10
          file.content_md5 = md5
          Rails.logger.info "Uploading #{key}"
          if file.save
            Rails.logger.info "Upload complete"
          else
            Rails.logger.error "!! Upload NOT complete !!"
          end
        else
          Rails.logger.info "Skipping #{key} because it hasn't changed"
        end
      end

      Rails.logger.info "Sync time stamp is #{timestamp}"
      directory.files.create(key: "#{subfolder}/#{@options[:s3_timestamp_file]}", body: timestamp)
    end

    private

    def service
      return unless @options[:s3_sync_enabled]

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
