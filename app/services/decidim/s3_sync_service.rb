# frozen_string_literal: true

require "fog/aws"
require "digest"

module Decidim
  class S3SyncService
    include Decidim::BackupHelper

    def self.run(options = {})
      new(options).execute
    end

    def initialize(options)
      @options = default_options.merge(options)
    end

    def default_options
      {
        datestamp: Time.zone.now.strftime("%Y-%m-%d"),
        force_upload: false,
        local_backup_dir: Rails.application.config.backup[:directory],
        local_backup_files: [],
        s3_region: Rails.application.config.backup.dig(:s3sync, :region),
        s3_endpoint: Rails.application.config.backup.dig(:s3sync, :endpoint),
        s3_bucket: Rails.application.config.backup.dig(:s3sync, :bucket),
        s3_access_key: Rails.application.config.backup.dig(:s3sync, :access_key),
        s3_secret_key: Rails.application.config.backup.dig(:s3sync, :secret_key),
        s3_subfolder: Rails.application.config.backup.dig(:s3sync, :subfolder),
        s3_timestamp_file: Rails.application.config.backup.dig(:s3sync, :timestamp_file)
      }
    end

    def has_local_backup_directory?
      File.directory?(@options[:local_backup_dir]) & File.readable?(@options[:local_backup_dir])
    end

    def subfolder
      @subfolder ||= @options[:subfolder].presence || generate_subfolder_name
    end

    def force_upload?
      @options[:force_upload]
    end

    def timestamp
      @timestamp ||= Time.zone.now.strftime("%Y-%m-%d-%H%M%S")
    end

    def file_list
      if @options[:local_backup_files].empty?
        Dir.children(@options[:local_backup_dir]).map do |filename|
          "#{@options[:local_backup_dir]}/#{filename}"
        end
      else
        @options[:local_backup_files]
      end
    end

    def execute
      directory = service.directories.get(@options[:s3_bucket], prefix: subfolder)

      file_list.each do |filename|
        md5 = Digest::MD5.file(filename)
        key = "#{subfolder}/#{File.basename(filename)}"

        old_file = directory.files.head(key)
        # the HEAD request does not send back the content_md5 value (base64)
        # we make the comparison with the etag field which host the Hex MD5 value

        if old_file.nil? || force_upload? || old_file.etag != md5.hexdigest
          file = directory.files.new(key: key, body: File.open(filename))
          file.multipart_chunk_size = 10 * 1024 * 1024
          file.concurrency = 10
          # This is used by the Object Storage service to validate the uploaded file
          file.content_md5 = md5.base64digest
          Rails.logger.info "Uploading #{key}"
          if file.save
            Rails.logger.info "Upload complete"
            data = file.service.put_object_tagging(directory.key, key, { date: @options[:datestamp] })
            if data.status == 200
              Rails.logger.info "Tagging complete"
            else
              Rails.logger.error "!! Tagging NOT complete !!"
              Rails.logger.error data
            end
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
