# frozen_string_literal: true

require "digest"

module Decidim
  class AssetsHash
    def initialize
      @app_dependencies_patterns = %w(Gemfile Gemfile.lock package.json yarn.lock)
      @assets_patterns = %w(app/assets/**/* app/packs/**/* vendor/**/* packages/**/* lib/assets/**/*)
    end

    def self.run
      new.run
    end

    def run
      app_assets_hashes = files_digest(@assets_patterns)
      app_dependencies_hashes = files_digest(@app_dependencies_patterns)

      digest("#{app_assets_hashes}#{app_dependencies_hashes}")
    end

    def files_digest(patterns)
      # TODO: Investigate on inconsistency results on CI, sometimes the hash generated is different for the slice 1-2 without apparent reason.
      Array.wrap(patterns).map { |pattern| Dir.glob(pattern) }
           .flatten
           .sort
           .select { |file| File.file?(file) }
           .map { |file| digest(File.read(file)) }
           .join("\n")
    end

    private

    def digest(value)
      Digest::SHA256.hexdigest(value)
    end
  end
end
