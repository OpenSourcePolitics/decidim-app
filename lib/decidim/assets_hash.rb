# frozen_string_literal: true

require "digest"

module Decidim
  class AssetsHash
    def self.run
      new.run
    end

    def run
      hash("#{app_assets_hash}#{app_dependencies_hash}")
    end

    private

    def app_dependencies_hash
      hash(app_dependencies_files)
    end

    def app_dependencies_files
      files_cat("Gemfile", "Gemfile.lock", "package.json", "yarn.lock")
    end

    def app_assets_hash
      hash(app_assets_files)
    end

    def app_assets_files
      files_cat(assets_pattern)
    end

    def assets_pattern
      %w(app/assets/**/* app/packs/**/* vendor/**/* packages/**/* lib/assets/**/*)
    end

    def hash(value)
      Digest::SHA256.hexdigest(value)
    end

    def files_cat(*files)
      files.map { |pattern| Dir.glob(pattern) }
           .flatten
           .select { |file| File.file?(file) }
           .map(&File.method(:read))
           .join("\n")
    end
  end
end
