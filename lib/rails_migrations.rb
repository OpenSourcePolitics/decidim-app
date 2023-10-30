# frozen_string_literal: true

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
