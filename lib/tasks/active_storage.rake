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
      include ActionView::Helpers::NumberHelper

      LIMIT = ENV.fetch("S3_LIMIT", "1000").to_i
      Rails.logger.info "Looking for orphan blobs in S3... (limit: #{LIMIT})"
      objects = ActiveStorage::Blob.service.bucket.objects
      Rails.logger.info "Total files: #{objects.size}"

      current_iteration = 0
      sum = 0
      orphans_count = 0
      objects.each do |obj|
        break if current_iteration >= LIMIT

        current_iteration += 1
        next if ActiveStorage::Blob.exists?(key: obj.key)

        Rails.logger.info "Removing orphan: #{obj.key}"
        sum += obj.size
        orphans_count += 1
        obj.delete
      end

      Rails.logger.info "Size: #{number_to_human_size(sum)} in #{orphans_count} files"
      Rails.logger.info "Configuration limit is #{LIMIT} files"
      Rails.logger.info "Terminated task... "
    end
  end
end
