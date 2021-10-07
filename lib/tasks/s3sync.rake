# frozen_string_literal: true

require 'fog/aws'
require 'digest'

LOCAL_BACKUP_DIR = Rails.application.config.backup.dig(:directory)
S3_REGION = Rails.application.config.backup.dig(:s3sync, :region)
S3_ENDPOINT = Rails.application.config.backup.dig(:s3sync, :endpoint)
S3_BUCKET = Rails.application.config.backup.dig(:s3sync, :bucket)
S3_ACCESS_KEY = Rails.application.config.backup.dig(:s3sync, :access_key)
S3_SECRET_KEY = Rails.application.config.backup.dig(:s3sync, :secret_key)
S3_SUBFOLDER = Rails.application.config.backup.dig(:s3sync, :subfolder)
S3_TIMESTAMP_FILE = Rails.application.config.backup.dig(:s3sync, :timestamp_file)

namespace :decidim do
  namespace :s3sync do

    def init
      Rails.logger = Logger.new($stdout) if task.application.tty_output?
      Rails.logger.info "#{task.application.top_level_tasks} starting"
    end

    def finish
      Rails.logger.info "#{task.application.top_level_tasks} finish"
      Rails.logger.close
    end

    def has_local_backup_directory?
      File.directory?(LOCAL_BACKUP_DIR) & File.readable?(LOCAL_BACKUP_DIR)
    end

    def generate_subfolder_name
      [
        `hostname`,
        File.basename(`git rev-parse --show-toplevel`),
        `git branch --show-current`
      ].map { |e| e.parameterize }.join("--")
    end

    def subfolder
      @subfolder ||= S3_SUBFOLDER.presence || generate_subfolder_name
    end

    def verbose?
      @verbose ||= ARGV.include?("-v") || ARGV.include?("--verbose")
    end

    def force_upload?
      @force_upload ||= ARGV.include?("--force")
    end

    def timestamp
      @timestamp ||= Time.now.strftime("%Y-%m-%d-%H%M%S")
    end

    desc "Synchronize backup files to object storage"
    task backup: :environment do
      init
      
      service = Fog::Storage.new(
        provider: "AWS", 
        aws_access_key_id: S3_ACCESS_KEY,
        aws_secret_access_key: S3_SECRET_KEY,
        region: S3_REGION,
        endpoint: S3_ENDPOINT,
        aws_signature_version: 4,
        enable_signature_v4_streaming: false
      )

      directory = service.directories.get("osp-backup-dev", prefix: subfolder)
      
      Dir.each_child(LOCAL_BACKUP_DIR) do |filename|
        md5 = Digest::MD5.file("#{LOCAL_BACKUP_DIR}/#{filename}").base64digest
        key = "#{subfolder}/#{filename}"

        old_file = directory.files.head(key: key)
        
        if old_file.nil? || force_upload? || old_file.content_md5 != md5
          file = directory.files.new(key: key, body: File.open("#{LOCAL_BACKUP_DIR}/#{filename}"))
          file.multipart_chunk_size = 10 * 1024 * 1024
          file.concurrency = 10
          file.content_md5 = md5
          Rails.logger.info "Uploading #{key}"
          if file.save()
            Rails.logger.info "Upload complete"
          else
            Rails.logger.error "!! Upload NOT complete !!"
          end
        else
          Rails.logger.info "Skipping #{key} because it hasn't changed"
        end
      end # Dir.each_child
      
      Rails.logger.info "Sync time stamp is #{timestamp}"
      directory.files.create(key: "#{subfolder}/#{S3_TIMESTAMP_FILE}", body: timestamp)

      finish
    end
    
  end
end
