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

      objects = ActiveStorage::Blob.service.bucket.objects
      puts "Total files: #{objects.size}"

      orphan = objects.reject do |obj|
        ActiveStorage::Blob.exists?(key: obj.key)
      end

      sum = 0
      orphan.each do |obj|
        sum += obj.size
        obj.delete
      end

      puts "Size: #{number_to_human_size(sum)} in #{orphan.size} files"
    end
  end
end
