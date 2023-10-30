# frozen_string_literal: true

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
    osp_app_path ||= File.expand_path(ENV.fetch("MIGRATIONS_PATH", nil))
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
