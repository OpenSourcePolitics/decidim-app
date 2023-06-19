# frozen_string_literal: true

require "active_storage/migrator"

namespace :scaleway do
  namespace :storage do
    desc "Migrate Active Storage from local to scaleway"
    task migrate_from_local: :environment do
      ActiveStorage::Migrator.migrate!(:local, :scaleway)
    end
  end
end
