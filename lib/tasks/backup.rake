# frozen_string_literal: true

require 'sys/filesystem'

DISK_SPACE_LIMIT = Rails.application.config.backup.dig(:disk_space_limit)
DB_CONF = Rails.configuration.database_configuration[Rails.env].deep_symbolize_keys
PWD = task.application.original_dir
BACKUP_DIR = Rails.application.config.backup.dig(:directory)
BACKUP_PREFIX = Rails.application.config.backup.dig(:prefix)
BACKUP_TIMESTAMP_FILE = Rails.application.config.backup.dig(:timestamp_file)

namespace :decidim do
  namespace :backup do

    def init
      Rails.logger = Logger.new($stdout) if task.application.tty_output?
      Rails.logger.info "#{task.application.top_level_tasks} starting"

      Rails.logger.info task
      Rails.logger.info ARGV

      unless has_backup_directory?
        Rails.logger.error "Directory #{BACKUP_DIR} not exist or writable"
        exit 1
      end

      unless has_enough_disk_space?
        Rails.logger.error "Not enough space on disk : #{available_space}G"
        exit 1
      end
    end

    def finish
      Rails.logger.info "#{task.application.top_level_tasks} finish"
      Rails.logger.close
    end

    def can_connect_to_db?
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection
      ActiveRecord::Base.connected?
    end

    def available_space
      disk_stats = Sys::Filesystem.stat(PWD)
      @available_space ||= disk_stats.block_size * disk_stats.blocks_available / 1024 / 1024 / 1024
    end

    def has_enough_disk_space?
      available_space > DISK_SPACE_LIMIT
    end

    def has_backup_directory?
      system "mkdir -p #{BACKUP_DIR}" unless File.directory?(BACKUP_DIR)
      File.writable?(BACKUP_DIR)
    end

    def need_timestamp?
      @need_timestamp ||= !ARGV.include?("--no-timestamp")
    end

    def verbose?
      @verbose ||= ARGV.include?("-v") || ARGV.include?("--verbose")
    end

    def timestamp
      @timestamp ||= Time.now.strftime("%Y-%m-%d-%H%M%S")
    end

    def generate_backup_file_path(name, ext)
      path = BACKUP_DIR
      path += "/#{BACKUP_PREFIX}-#{name}"
      path += "-#{timestamp}" if need_timestamp?
      path += ".#{ext}"
    end

    def execute_backup_command(file, cmd)
      Rails.logger.info "Command : #{cmd}" if verbose?
      result = system cmd
      Rails.logger.info "Created file #{file} with exit code #{result}"
    end

    def backup_database
      if can_connect_to_db?
        file = generate_backup_file_path("db", "dump")

        cmd = "pg_dump -Fc"
        cmd += " -h '#{DB_CONF[:host]}'" if DB_CONF[:host].present?
        cmd += " -p '#{DB_CONF[:port]}'" if DB_CONF[:port].present?
        cmd += " -U '#{DB_CONF[:username]}'" if DB_CONF[:username].present?
        cmd = "PGPASSWORD=#{DB_CONF[:password]} #{cmd}" if DB_CONF[:password].present?
        cmd += " -d '#{DB_CONF[:database]}'" if DB_CONF[:database].present?
        cmd += " -f '#{file}'"
  
        execute_backup_command(file, cmd)
      else
        Rails.logger.error "Cannot connect to DB with configuration"
        Rails.logger.error DB_CONF.except(:password)
        Rails.logger.error "DB password was #{DB_CONF[:password].present? ? "present" : "missing"}"
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
        system "git status -s > git-status.txt"
        git_delta = File.read("git-status.txt").split()
  
        file_list = [
          "git-status.txt",
          ".git/HEAD",
          ".git/ORIG_HEAD",
        ].concat(git_delta.select.with_index {|e, i| i.odd?})
  
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
      File.write("#{BACKUP_DIR}/#{BACKUP_TIMESTAMP_FILE}", timestamp)
    end

    desc "Backup Database"
    task db: :environment do
      init
      backup_database
      finish
    end

    desc "Backup uploads"
    task uploads: :environment do
      init
      backup_uploads
      finish
    end

    desc "Backup env"
    task env: :environment do
      init
      backup_env
      finish
    end

    desc "Backup git"
    task git: :environment do
      init
      backup_git
      finish
    end

    desc "Backup all"
    task all: :environment do
      init
      backup_database
      backup_uploads
      backup_env
      backup_git
      generate_timestamp_file
      finish
    end
    
  end
end
