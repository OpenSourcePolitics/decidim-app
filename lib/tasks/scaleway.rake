# frozen_string_literal: true

namespace :scaleway do
  namespace :storage do
    desc "Migrate Active Storage from local to scaleway"
    task migrate_from_local: :environment do
      # inspired from https://www.stefanwienert.de/blog/2018/11/05/active-storage-migrate-between-providers-from-local-to-amazon/
      migrate(:local, :scaleway)
    end
  end
end

module AsDownloadPatch
  def open(tempdir: nil, &block)
    ActiveStorage::Downloader.new(self, tempdir: tempdir).download_blob_to_tempfile(&block)
  end
end

Rails.application.config.to_prepare do
  ActiveStorage::Blob.include AsDownloadPatch
end

def migrate(from, to)
  logger = LoggerWithStdout.new("log/active-storage-migrate-from-#{from}-to-#{to}-#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
  configs = Rails.configuration.active_storage.service_configurations
  from_service = ActiveStorage::Service.configure from, configs
  to_service = ActiveStorage::Service.configure to, configs

  ActiveStorage::Blob.service = from_service

  logger.info "#{ActiveStorage::Blob.count} Blobs to go..."
  ActiveStorage::Blob.find_each do |blob|
    logger.info "migrating blob #{blob.key}"
    blob.open do |tf|
      checksum = blob.checksum
      to_service.upload(blob.key, tf, checksum: checksum)
    end
  rescue ActiveStorage::FileNotFoundError
    logger.error "FileNotFoundError #{blob.key}"
    next
  end
end
