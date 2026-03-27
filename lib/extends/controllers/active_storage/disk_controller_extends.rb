# frozen_string_literal: true

module DiskControllerExtends
  extend ActiveSupport::Concern

  included do
    private

    # Failsafe method to retrieve the disk service, even if the service name is not configured in the blob's metadata
    # This can happended with hard coded links generated in Rails 6.0
    def named_disk_service(name)
      failsafe_name = name || ActiveStorage::Blob.service.name
      ActiveStorage::Blob.services.fetch(failsafe_name) do
        ActiveStorage::Blob.service
      end
    end
  end
end

ActiveStorage::DiskController.class_eval do
  include(DiskControllerExtends)
end
