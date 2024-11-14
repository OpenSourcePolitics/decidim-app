# frozen_string_literal: true

namespace :active_storage do
  namespace :purge do
    desc "Purge orphan blobs in databa"
    task blobs: :environment do
      Rails.logger.info "Looking for blobs without attachments in database..."
      blobs = ActiveStorage::Blob.where.not(id: ActiveStorage::Attachment.select(:blob_id))

      if blobs.count.zero?
        Rails.logger.info "Database is clean !"
        Rails.logger.info "Terminating task..."
      else
        Rails.logger.info "Found #{blobs.count} orphan blobs !"
        blobs.each(&:purge)
        Rails.logger.info "Task terminated !"
      end
    end

    desc "Purge orphan blobs in S3"
    task s3: :environment do
      limit = ENV.fetch("S3_LIMIT", "10000").to_i
      ActiveStorageClearOrphansJob.perform_later(limit: limit)
    end
  end
end
