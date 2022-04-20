# frozen_string_literal: true

namespace :decidim do
  namespace :db do
    desc "Migrate Database"
    task migrate: :environment do
      logger = LoggerWithStdout.new("log/db-migrations-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")

      migration_fixer = MigrationsFixer.new(logger)
      rails_migrations = RailsMigrations.new(migration_fixer)

      logger.info("#{rails_migrations.fetch_all.count} migrations are present.")
      logger.info("#{rails_migrations.down.count} migrations seems to be missing...")
      logger.info("#{rails_migrations.not_found.count} migrations registered but not found in current project, must be compared with previous migrations folder.")

      if rails_migrations.down.blank?
        logger.info("All migrations seems to be 'up', end of task")
        exit 0
      end

      rails_migrations.display_status!

      versions_migration_success = []
      versions_migration_forced = []

      rails_migrations.versions_down_but_already_passed&.each do |version|
        next if ActiveRecord::SchemaMigration.find_by(version: version).present?

        ActiveRecord::SchemaMigration.create!(version: version)
        versions_migration_success << version
        logger.info("Migration '#{version}' up")
      end

      rails_migrations.reload_down!&.each do |_status, version, _name|
        # Migration up each version one by one
        migration_process = `bundle exec rails db:migrate:up VERSION=#{version}`

        # If db:migrate:up tasks outputs a message containing "migrated", then we consider success
        # Else we force the migration version in database since it may have already been migrated
        if migration_process.include?("migrated")
          versions_migration_success << version
          logger.info("Migration '#{version}' successfully migrated")
        else
          logger.warn("Migration '#{version}' failed, validating directly in database schema migrations...")
          logger.warn(migration_process)
          if ActiveRecord::SchemaMigration.find_by(version: version).blank?
            ActiveRecord::SchemaMigration.create!(version: version)
            versions_migration_forced << version
            logger.info("Migration '#{version}' successfully marked as up")
          end
        end
      end

      logger.info("--------- Well passed migrations ------------")
      logger.info(versions_migration_success)

      logger.info("--------- Failing migrations marked as 'up' ------------")
      logger.info(versions_migration_forced)

      rails_migrations.reload_migrations!
      rails_migrations.display_status!

      logger.info("#{versions_migration_success.count} migrations passed successfully")
      logger.info("#{versions_migration_forced.count} migrations failed but was marked as 'up' directly in database")
      logger.info("All migrations passed, end of task")

      exit 0
    end
  end
end

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

# RailsMigrations deals with migrations of the project
class RailsMigrations
  attr_accessor :fetch_all

  def initialize(migration_fixer)
    @fetch_all = migration_status
    @migration_fixer = migration_fixer
  end

  # Reload down migrations according to the new migration status
  def reload_down!
    @down = nil
    reload_migrations!
    down
  end

  # Return all migrations marked as 'down'
  def down
    @down ||= @fetch_all&.map do |migration_ary|
      migration_ary if migration_ary&.first == "down"
    end.compact
  end

  # Refresh all migrations according to DB
  def reload_migrations!
    @fetch_all = migration_status
  end

  # Print migrations status
  def display_status!
    @fetch_all&.each do |status, version, name|
      @migration_fixer.logger.info("#{status.center(8)}  #{version.ljust(14)}  #{name}")
    end
  end

  # Returns all migration present in DB but with no migration files defined
  def not_found
    @not_found ||= @fetch_all&.map { |_, version, name| version if name.include?("NO FILE") }.compact
  end

  # returns all versions marked as 'down' but already passed in past
  # This methods is based on migration filenames from osp-app folder, then compare with current migration folder and retrieve duplicated migration with another version number
  # Returns array of 'down' versions
  def versions_down_but_already_passed
    needed_migrations = already_accepted_migrations&.map do |migration|
      Dir.glob("#{@migration_fixer.migrations_path}/*#{migration_name_for(migration)}")
    end.flatten!

    needed_migrations&.map { |filename| migration_version_for(filename) }
  end

  private

  # returns the migration name based on migration version
  # Example for migration : 11111_add_item_in_class
  # @return : add_item_in_class
  def migration_name_for(migration)
    migration.split("/")[-1].split("_")[1..-1].join("_")
  end

  # Returns the migration version based on migration filename
  # Example for migration : 11111_add_item_in_class
  # @return : 11111
  def migration_version_for(migration)
    migration.split("/")[-1].split("_")[0]
  end

  # returns migrations filename from old osp-app folder, based on versions present in database with no file related
  def already_accepted_migrations
    @already_accepted_migrations ||= not_found&.map do |migration|
      osp_app = Dir.glob("#{@migration_fixer.osp_app_path}*")&.select { |path| path if path.include?(migration) }

      osp_app.first if osp_app.present?
    end.compact
  end

  # Fetch all migrations statuses
  def migration_status
    ActiveRecord::Base.connection.migration_context.migrations_status
  end
end

# MigrationsFixer allows to ensure rake task has needed information to success.
class MigrationsFixer
  attr_accessor :migrations_path, :logger

  def initialize(logger)
    @logger = logger
    @migrations_path = Rails.root.join(migrations_folder)
    validate!
    @osp_app_path = osp_app_path
  end

  # Validate configuration before executing task
  def validate!
    raise "Undefined logger" if @logger.blank?

    validate_migration_path
    validate_env_vars
    validate_osp_app_path
  end

  # Build osp-app path and returns osp-app path ending with '/*'
  def osp_app_path
    osp_app_path ||= File.expand_path(ENV["MIGRATIONS_PATH"])
    if osp_app_path.end_with?("/")
      osp_app_path
    else
      "#{osp_app_path}/"
    end
  end

  private

  # Ensure MIGRATIONS_PATH is correctly set
  def validate_env_vars
    if ENV["MIGRATIONS_PATH"].blank?
      @logger.error("You must specify ENV var 'MIGRATIONS_PATH'")

      @logger.fatal(helper)
      exit 2
    end
  end

  # Ensure osp_app path exists
  def validate_osp_app_path
    unless File.directory?(osp_app_path)
      @logger.fatal("Directory '#{osp_app_path}' not found, aborting task...")
      exit 2
    end
  end

  # Ensure migrations path exists
  def validate_migration_path
    unless File.directory? @migrations_path
      @logger.error("Directory '#{@migrations_path}' not found, aborting task...")
      @logger.error("Please see absolute path '#{File.expand_path(@migrations_path)}'")

      @logger.fatal("Please ensure the migration path is correctly defined.")
      exit 2
    end
  end

  # Returns path to DB migrations (default: "db/migrate")
  def migrations_folder
    ActiveRecord::Base.connection.migration_context.migrations_paths.first
  end

  # Display helper
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
