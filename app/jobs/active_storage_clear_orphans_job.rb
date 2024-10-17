# frozen_string_literal: true

class ActiveStorageClearOrphansJob < ApplicationJob
  include ActionView::Helpers::NumberHelper
  queue_as :default

  def perform(**args)
    limit = args[:limit] || 10_000
    Rails.logger.info "Looking for orphan blobs in S3... (limit: #{limit})"
    objects = ActiveStorage::Blob.service.bucket.objects
    Rails.logger.info "Total files: #{objects.size}"

    current_iteration = 0
    sum = 0
    orphans_count = 0
    objects.each do |obj|
      break if current_iteration >= limit

      current_iteration += 1
      next if ActiveStorage::Blob.exists?(key: obj.key)

      sum += delete_object(obj)
      orphans_count += 1
    end

    Rails.logger.info "Size: #{number_to_human_size(sum)} in #{orphans_count} files"
    Rails.logger.info "Configuration limit is #{limit} files"
    Rails.logger.info "Terminated task... "
  end

  private

  def delete_object(obj)
    Rails.logger.info "Removing orphan: #{obj.key}"
    size = obj.size
    obj.delete
    size
  end
end
