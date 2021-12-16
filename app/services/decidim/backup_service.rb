# frozen_string_literal: true

require "sys/filesystem"
require "fog/aws"
require "digest"
require "fileutils"

module Decidim
  class BackupService
    def initialize(options)
      @options = default_options.merge(options)
      @local_files = []
    end

    def self.run(options = {})
      new(options).execute
    end

    def execute
      create_backup_dir

      if has_enough_disk_space?
        create_backup_export

        if @options[:s3sync]
          Decidim::S3SyncService.run(
            datestamp: Time.zone.now.strftime("%Y-%m-%d"),
            local_backup_files: @local_files
          )
        end

        Decidim::S3RetentionService.run if @options[:s3retention]

        clean_local_files unless @options[:keep_local_files]
      else
        Rails.logger.error "Not enough space left for backup : #{available_space} Go available for #{@options[:disk_space_limit]} Go needed"
      end
    end

    def default_options
      {
        disk_space_limit: Rails.application.config.backup[:disk_space_limit],
        db_conf: Rails.configuration.database_configuration[Rails.env].deep_symbolize_keys,
        backup_dir: Rails.application.config.backup[:directory],
        backup_prefix: Rails.application.config.backup[:prefix],
        backup_timestamp_file: Rails.application.config.backup[:timestamp_file],
        timestamp_in_filename: true,
        s3sync: Rails.application.config.backup.dig(:s3sync, :enabled),
        s3retention: Rails.application.config.backup.dig(:s3retention, :enabled),
        keep_local_files: true,
        scope: :all
      }
    end

    def create_backup_dir
      backup_dir = Rails.root.join(@options[:backup_dir])
      return if File.exist?(backup_dir)

      FileUtils.mkdir_p(backup_dir)
    end

    def create_backup_export
      backup_database if check_scope?(:db)
      backup_uploads if check_scope?(:uploads)
      backup_env if check_scope?(:env)
      backup_git if check_scope?(:git)
      generate_timestamp_file unless @options[:timestamp_in_filename]
    end

    def backup_database
      if can_connect_to_db?
        file = generate_backup_file_path("db", "dump")

        cmd = "pg_dump -Fc"
        cmd += " -h '#{@options[:db_conf][:host]}'" if @options[:db_conf][:host].present?
        cmd += " -p '#{@options[:db_conf][:port]}'" if @options[:db_conf][:port].present?
        cmd += " -U '#{@options[:db_conf][:username]}'" if @options[:db_conf][:username].present?
        cmd = "PGPASSWORD=#{@options[:db_conf][:password]} #{cmd}" if @options[:db_conf][:password].present?
        cmd += " -d '#{@options[:db_conf][:database]}'" if @options[:db_conf][:database].present?
        cmd += " -f '#{file}'"

        Rails.logger.info("Started backup_database with #{cmd}")

        execute_backup_command(file, cmd)
      else
        Rails.logger.error "Cannot connect to DB with configuration"
        Rails.logger.error @options[:db_conf].except(:password)
        Rails.logger.error "DB password was #{@options[:db_conf][:password].present? ? "present" : "missing"}"
        # do not exit here because we can still try to do the other backups
      end
    end

    def backup_uploads
      if File.exist?("public/uploads")
        file = generate_backup_file_path("uploads", "tar.bz2")

        cmd = "tar -jcf #{file} --exclude='public/uploads/tmp' public/uploads"

        execute_backup_command(file, cmd)
      else
        Rails.logger.warn "uploads directory not found"
        # do not exit here because we can still try to do the other backups
      end
    end

    def backup_env
      if File.exist?(".env")
        file = generate_backup_file_path("env", "tar.bz2")

        cmd = "tar -jcf #{file} .env"

        execute_backup_command(file, cmd)
      else
        Rails.logger.warn ".env file not found"
        # do not exit here because we can still try to do the other backups
      end
    end

    def backup_git
      if File.exist?(".git")
        git_delta = `git status -s`.split("\n")
                                   .map(&:split)
                                   .map { |array| array[1] }

        file_list = %w(.git/HEAD .git/ORIG_HEAD).concat(git_delta)
                                                .select { |file| File.exist? file }

        file = generate_backup_file_path("git", "tar.bz2")

        cmd = "tar -jcf #{file} #{file_list.join(" ")}"

        execute_backup_command(file, cmd)
      else
        Rails.logger.warn ".git directory not found"
        # do not exit here because we can still try to do the other backups
      end
    end

    def generate_timestamp_file
      Rails.logger.info "Backup time stamp is #{timestamp}"
      file = "#{@options[:backup_dir]}/#{@options[:backup_timestamp_file]}"
      File.write(file, timestamp)
      @local_files << file
    end

    protected

    def can_connect_to_db?
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection
      ActiveRecord::Base.connected?
    end

    def available_space
      disk_stats = Sys::Filesystem.stat(Rails.root.to_s)
      @available_space ||= disk_stats.block_size * disk_stats.blocks_available / 1024 / 1024 / 1024
    end

    def has_enough_disk_space?
      available_space > @options[:disk_space_limit]
    end

    def has_backup_directory?
      system "mkdir -p #{@options[:backup_dir]}" unless File.directory?(@options[:backup_dir])
      File.writable?(@options[:backup_dir])
    end

    def need_timestamp?
      @options[:timestamp_in_filename]
    end

    def timestamp
      @timestamp ||= Time.zone.now.strftime("%Y-%m-%d-%H%M%S")
    end

    def generate_backup_file_path(name, ext)
      path = @options[:backup_dir]
      path += "/#{@options[:backup_prefix]}-#{name}"
      path += "-#{timestamp}" if need_timestamp?

      "#{path}.#{ext}"
    end

    def execute_backup_command(file, cmd)
      Rails.logger.info "Command : #{cmd}"
      result = system(cmd)
      @local_files << file if result
      Rails.logger.info "Created file #{file} with exit code #{$CHILD_STATUS}"
    end

    def clean_local_files
      FileUtils.rm(@local_files)
    end

    def check_scope?(scope)
      return true if @options[:scope] == :all

      @options[:scope] == scope
    end
  end
end
