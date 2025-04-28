# frozen_string_literal: true

namespace :active_storage do
  desc "Update ActiveStorage service name in the database (FROM_SERVICE and TO_SERVICE env variables required)."
  task :update_service_name, [:actual_service_name, :target_service_name] => :environment do |_, args|
    raise ArgumentError, "Missing FROM_SERVICE (source) or TO_SERVICE (destination) environment variables" if ENV["FROM_SERVICE"].blank? || ENV["TO_SERVICE"].blank?

    from_service = ENV.fetch("FROM_SERVICE") || args[:actual_service_name]
    to_service = ENV.fetch("TO_SERVICE") || args[:target_service_name]

    if from_service == to_service || from_service.blank? || to_service.blank?
      Rails.logger.warn "(storage:update_service_name)> No changes needed, exiting task."
      next
    end

    Rails.logger.warn "(storage:update_service_name)> Updating ActiveStorage::Blob service name from '#{from_service}' to '#{to_service}'"

    records = ActiveStorage::Blob.where(service_name: from_service)
    Rails.logger.warn "(storage:update_service_name)> Found #{records.count} blobs with service name '#{from_service}'"

    # rubocop:disable Rails/SkipsModelValidations
    records.update_all(service_name: to_service)
    # rubocop:enable Rails/SkipsModelValidations

    Rails.logger.warn "(storage:update_service_name)> All blobs updated from '#{from_service}' to '#{to_service}'"
  end
end
