# frozen_string_literal: true

class LoggerWithStdout < Logger
  def initialize(*)
    super

    def @logdev.write(msg)
      super

      puts msg
    end
  end
end

namespace :decidim do
  namespace :db do
    desc "Migrate Database"
    task migrate: :environment do
      logger = LoggerWithStdout.new("log/db-migrations-#{DateTime.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")

      migrations_folder_path = Rails.root.join migrations_folder
      check_config_or_exit(logger, migrations_folder_path)
      osp_app_path = build_osp_app_path

      if File.directory?(osp_app_path)
        logger.error("Directory '#{osp_app_path}' not found, aborting task...")
        exit 1
      end

      migrations = migration_status
      migrations_down = migration_status.map { |migration_array| migration_array if migration_array.first == "down" }.compact
      migrations_not_found = []

      migrations.each do |status, version, name|
        puts "#{status.center(8)}  #{version.ljust(14)}  #{name}"

        migrations_not_found << version if name.include?("NO FILE")
      end

      logger.info("#{migrations.count} migrations are present.")
      logger.info("#{migrations_down.count} migrations seems to be missing...")
      logger.info("#{migrations_not_found.count} migrations registered but not found in current project, must be compared with previous migrations folder.")

      if migrations_down.blank?
        logger.info("All migrations seems to be 'up', end of task")
        exit 0
      end

      # accepted_migrations contains all migration files from old decidim-app
      accepted_migrations = []
      # needed_migrations contains all migration files from current app, based on the ones present in accepted_migrations
      needed_migrations = []

      # Retrieve migration file for versions not found
      migrations_not_found.each do |migration|
        osp_app = Dir.glob(osp_app_path).select { |path| path if path.include?(migration) }

        accepted_migrations << osp_app.first unless osp_app.blank?
      end

      # Retrieve migration file for not found ones
      accepted_migrations.each do |migration|
        needed_migrations << Dir.glob("#{migrations_folder_path}/*#{migration.split("/")[-1].split("_")[1..-1].join("_")}")
      end

      already_existing_versions = needed_migrations.map { |ary| ary.first.split("/")[-1].split("_")[0] }

      count_ok = []
      count_nok = []

      already_existing_versions.each do |version|
        if ActiveRecord::SchemaMigration.find_by(version: version).blank?
          ActiveRecord::SchemaMigration.create!(version: version)
          count_ok << version
          logger.info("Migration '#{version}' up")
        end
      end

      migrations_down = migration_status.map { |migration_array| migration_array.second if migration_array.first == "down" }.compact

      migrations_down.each do |down|
        migration_process = `bundle exec rails db:migrate:up VERSION=#{down}`
        if migration_process.include?("migrated")
          count_ok << down
          logger.info("Migration '#{down}' successfully migrated")
        else
          logger.warn("Migration '#{down}' failed, validating directly in database schema migrations...")
          logger.warn(migration_process)
          if ActiveRecord::SchemaMigration.find_by(version: down).blank?
            ActiveRecord::SchemaMigration.create!(version: down)
            count_nok << down
            logger.info("Migration '#{down}' successfully marked as up")
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
