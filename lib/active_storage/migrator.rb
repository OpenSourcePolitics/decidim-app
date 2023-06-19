# frozen_string_literal: true

require "logger_with_stdout"

# inspired from https://www.stefanwienert.de/blog/2018/11/05/active-storage-migrate-between-providers-from-local-to-amazon/
module ActiveStorage
  class Migrator
    def initialize(source, destination)
      @source_service = provider_to_service(source)
      @destination_service = provider_to_service(destination)
      @logger = LoggerWithStdout.new("log/active-storage-migrate-from-#{source}-to-#{destination}-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
    end

    def self.migrate!(source, destination)
      new(source, destination).migrate!
    end

    def migrate!
      ActiveStorage::Blob.service = @source_service

      @logger.info "#{ActiveStorage::Blob.count} Blobs to go..."
      ActiveStorage::Blob.find_each do |blob|
        @logger.info "migrating blob #{blob.key}"
        blob.open do |tf|
          checksum = blob.checksum
          @destination_service.upload(blob.key, tf, checksum: checksum)
        end
      rescue ActiveStorage::FileNotFoundError
        @logger.error "FileNotFoundError #{blob.key}"
        next
      end
    end

    private

    def active_storage_configurations
      @active_storage_configurations ||= Rails.configuration.active_storage.service_configurations.with_indifferent_access
    end

    def provider_to_service(provider)
      raise "Unknown provider #{provider}" unless active_storage_configurations.has_key?(provider)

      ActiveStorage::Service.configure(provider, active_storage_configurations)
    end
  end
end
