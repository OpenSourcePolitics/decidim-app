# frozen_string_literal: true

class LoggerWithStdout < Logger
  def initialize(*)
    super

    # rubocop:disable Lint/NestedMethodDefinition
    def @logdev.write(msg)
      super

      puts msg
    end
    # rubocop:enable Lint/NestedMethodDefinition
  end
end

class RailsMigrations
  attr_reader :fetch_all

  def initialize; end

  def down
    fetch_all.map do |migration_ary|
      migration_ary if migration_ary.first == "down"
    end.compact
  end

  def fetch_all
    ActiveRecord::Base.connection.migration_context.migrations_status
  end

  def display_status
    fetch_all.each do |status, version, name|
      @logger.info("#{status.center(8)}  #{version.ljust(14)}  #{name}")
    end
  end

  def not_found
    fetch_all.map { |_, version, name| version if name.include?("NO FILE") }.compact
  end
end

class MigrationsFixer
  attr_accessor :migrations_path, :logger
  attr_reader :osp_app_path

  def initialize(logger)
    @logger = logger
    @migrations_path = Rails.root.join(migrations_folder)
    @osp_app_path = osp_app_path
    validate!
  end

  def validate!
    raise "Undefined logger" if @logger.blank?

    validate_migration_path
    validate_env_vars
    validate_osp_app_path
  end

  def osp_app_path
    osp_app_path ||= File.expand_path(ENV["MIGRATIONS_PATH"])
    if osp_app_path.end_with?("/")
      "#{osp_app_path}*"
    elsif osp_app_path.end_with?("*")
      osp_app_path
    else
      "#{osp_app_path}/*"
    end
  end

  private

  def validate_env_vars
    if ENV["MIGRATIONS_PATH"].blank?
      @logger.error("You must specify ENV var 'MIGRATIONS_PATH'")

      @logger.fatal(helper)
    end
  end

  def validate_osp_app_path
    @logger.fatal("Directory '#{osp_app_path}' not found, aborting task...") if File.directory?(osp_app_path)
  end

  def validate_migration_path
    unless File.directory? @migrations_path
      @logger.error("Directory '#{@migrations_path}' not found, aborting task...")
      @logger.error("Please see absolute path '#{File.expand_path(@migrations_path)}'")

      @logger.fatal("Please ensure the migration path is correctly defined.")
    end
  end

  def migrations_folder
    ActiveRecord::Base.connection.migration_context.migrations_paths.first
  end

  def helper
    "Manual : decidim:db:migrate
Fix migrations issue when switching from osp-app to decidim-app. Rake task will automatically save already passed migrations from current project that are marked as 'down'.
Then it will try to migrate each 'down' version, if it fails, it automatically note as 'up'

Parametes:
* MIGRATIONS_PATH - String [Relative or absolute path] : Pass to previous decidim project

Example: bundle exec rake decidim:db:migrate MIGRATIONS_PATH='../osp-app/db/migrate'
or
bundle exec rake decidim:db:migrate MIGRATIONS_PATH='/Users/toto/osp-app/db/migrate'
"
  end
end

namespace :decidim do
  namespace :db do
    desc "Migrate Database"
    task migrate: :environment do
      logger = LoggerWithStdout.new("log/db-migrations-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")

      migration_fixer = MigrationsFixer.new(logger)
      rails_migrations = RailsMigrations.new

      logger.info("#{rails_migrations.fetch_all.count} migrations are present.")
      logger.info("#{rails_migrations.down.count} migrations seems to be missing...")
      logger.info("#{rails_migrations.not_found.count} migrations registered but not found in current project, must be compared with previous migrations folder.")

      if rails_migrations.down.blank?
        logger.info("All migrations seems to be 'up', end of task")
        exit 0
      end

      # accepted_migrations contains all migration files from old decidim-app
      accepted_migrations = []
      # needed_migrations contains all migration files from current app, based on the ones present in accepted_migrations
      needed_migrations = []

      # Retrieve migration file for versions not found
      rails_migrations.not_found.each do |migration|
        osp_app = Dir.glob(migration_fixer.osp_app_path).select { |path| path if path.include?(migration) }

        accepted_migrations << osp_app.first if osp_app.present?
      end

      # Retrieve migration file for not found ones
      accepted_migrations.each do |migration|
        needed_migrations << Dir.glob("#{migration_fixer.migrations_path}/*#{migration.split("/")[-1].split("_")[1..-1].join("_")}")
      end

      already_existing_versions = needed_migrations.map { |ary| ary.first.split("/")[-1].split("_")[0] }

      count_ok = []
      count_nok = []

      already_existing_versions.each do |version|
        next if ActiveRecord::SchemaMigration.find_by(version: version).present?

        ActiveRecord::SchemaMigration.create!(version: version)
        count_ok << version
        logger.info("Migration '#{version}' up")
      end


      rails_migrations.down.each do |down_ary|
        migration_process = `bundle exec rails db:migrate:up VERSION=#{down_ary.second}`
        if migration_process.include?("migrated")
          count_ok << down_ary.second
          logger.info("Migration '#{down_ary.second}' successfully migrated")
        else
          logger.warn("Migration '#{down_ary.second}' failed, validating directly in database schema migrations...")
          logger.warn(migration_process)
          if ActiveRecord::SchemaMigration.find_by(version: down_ary.second).blank?
            ActiveRecord::SchemaMigration.create!(version: down_ary.second)
            count_nok << down_ary.second
            logger.info("Migration '#{down_ary.second}' successfully marked as up")
          end
        end
      end

      logger.info("--------- Well passed migrations ------------")
      logger.info(count_ok)

      logger.info("--------- Failing migrations marked as 'up' ------------")
      logger.info(count_nok)

      logger.info("All migrations passed, end of task")
      logger.info("#{count_ok.count} migrations passed successfully")
      logger.info("#{count_nok.count} migrations failed but was marked as 'up' directly in database")
      exit 0
    end
  end
end

def migrations_folder
  ActiveRecord::Base.connection.migration_context.migrations_paths.first
end

def migration_status
  ActiveRecord::Base.connection.migration_context.migrations_status
end

def helper
  "Manual : decidim:db:migrate
Fix migrations issue when switching from osp-app to decidim-app. Rake task will automatically save already passed migrations from current project that are marked as 'down'.
Then it will try to migrate each 'down' version, if it fails, it automatically note as 'up'

Parametes:
* MIGRATIONS_PATH - String [Relative or absolute path] : Pass to previous decidim project

Example: bundle exec rake decidim:db:migrate MIGRATIONS_PATH='../osp-app/db/migrate'
or
bundle exec rake decidim:db:migrate MIGRATIONS_PATH='/Users/toto/osp-app/db/migrate'
"
end

def build_osp_app_path
  osp_app_path = File.expand_path(ENV["MIGRATIONS_PATH"])
  if osp_app_path.end_with?("/")
    "#{osp_app_path}*"
  elsif osp_app_path.end_with?("*")
    osp_app_path
  else
    "#{osp_app_path}/*"
  end
end

def check_config_or_exit(logger, migrations_folder_path)
  unless File.directory?(migrations_folder_path)
    logger.error("Directory '#{migrations_folder_path}' not found, aborting task...")
    exit 1
  end

  if ENV["MIGRATIONS_PATH"].blank?
    logger.error("You must specify ENV var 'MIGRATIONS_PATH'")
    puts helper
    exit 2
  end
end
