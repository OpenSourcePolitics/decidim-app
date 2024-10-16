# frozen_string_literal: true

namespace :active_storage do
  namespace :purge do
    desc "Purge orphan blobs in databa"
    task blobs: :environment do
      puts "Looking for blobs without attachments in database..."
      blobs = ActiveStorage::Blob.where.not(id: ActiveStorage::Attachment.select(:blob_id))

      if blobs.count.zero?
        puts "Database is clean !"
        puts "Terminating task..."
      else
        puts "Found #{blobs.count} orphan blobs !"

        ActiveStorage::Blob.where.not(id: ActiveStorage::Attachment.select(:blob_id)).find_each(&:purge)

        puts "Task terminated !"
      end
    end

    desc "Purge orphan blobs in S3"
    task s3: :environment do
      limit = ENV.fetch("S3_LIMIT", "10000").to_i
      ActiveStorageClearOrphansJob.perform_later(limit: limit)
    end
  end
end
