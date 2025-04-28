# frozen_string_literal: true

require "migrations_fixer"
require "rails_migrations"

# :nocov:
namespace :migrate do
  namespace :db do
    desc "Migrate Database"
    task force: :environment do
      logger = Rails.logger

      migration_fixer = MigrationsFixer.new(logger)
      rails_migrations = RailsMigrations.new(migration_fixer)

      logger.warn("#{rails_migrations.fetch_all.count} migrations are present.")
      logger.warn("#{rails_migrations.down.count} migrations seems to be missing...")
      logger.warn("#{rails_migrations.not_found.count} migrations registered but not found in current project, must be compared with previous migrations folder.")

      if rails_migrations.down.blank?
        logger.warn("All migrations seems to be 'up', end of task")
        next
      end

      rails_migrations.display_status!

      versions_migration_success = []
      versions_migration_forced = []

      rails_migrations.versions_down_but_already_passed&.each do |version|
        next if ActiveRecord::SchemaMigration.find_by(version:).present?

        ActiveRecord::SchemaMigration.create!(version:)
        versions_migration_success << version
        logger.warn("Migration '#{version}' up")
      end

      rails_migrations.reload_down!&.each do |_status, version, _name|
        # Migration up each version one by one
        migration_process = `bundle exec rails db:migrate:up VERSION=#{version}`

        # If db:migrate:up tasks outputs a message containing "migrated", then we consider success
        # Else we force the migration version in database since it may have already been migrated
        if migration_process.include?("migrated")
          versions_migration_success << version
          logger.warn("Migration '#{version}' successfully migrated")
        else
          logger.warn("Migration '#{version}' failed, validating directly in database schema migrations...")
          logger.warn(migration_process)
          if ActiveRecord::SchemaMigration.find_by(version:).blank?
            ActiveRecord::SchemaMigration.create!(version:)
            versions_migration_forced << version
            logger.warn("Migration '#{version}' successfully marked as up")
          end
        end
      end

      logger.warn("--------- Well passed migrations ------------")
      logger.warn(versions_migration_success)

      logger.warn("--------- Failing migrations marked as 'up' ------------")
      logger.warn(versions_migration_forced)

      rails_migrations.reload_migrations!
      rails_migrations.display_status!

      logger.warn("#{versions_migration_success.count} migrations passed successfully")
      logger.warn("#{versions_migration_forced.count} migrations failed but was marked as 'up' directly in database")
      logger.warn("All migrations passed, end of task")
    end
  end
end
# :nocov:
