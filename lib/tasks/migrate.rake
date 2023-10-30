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
