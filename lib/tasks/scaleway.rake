# frozen_string_literal: true

require "active_storage/migrator"

namespace :scaleway do
  namespace :storage do
    desc "Migrate Active Storage from local to scaleway"
    task migrate_from_local: :environment do
      ActiveStorage::Migrator.migrate!(
        ENV.fetch("ACTIVE_STORAGE_TO_MIGRATE_FROM", :local).to_sym,
        ENV.fetch("ACTIVE_STORAGE_TO_MIGRATE_TO", :scaleway).to_sym
      )
    end
  end
end
