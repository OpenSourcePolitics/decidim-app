# frozen_string_literal: true

module ActiveStorage
  module Downloadable
    def open(tempdir: nil, &block)
      ActiveStorage::Downloader.new(self, tempdir: tempdir).download_blob_to_tempfile(&block)
    end
  end
end
