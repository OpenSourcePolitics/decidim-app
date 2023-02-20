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

      File.write("tmp/assets_manifest.json", JSON.pretty_generate(app_assets_hashes))

      digest("#{app_assets_hashes.values.join("\n")}#{app_dependencies_hashes.values.join("\n")}")
    end

    def files_digest(patterns)
      # TODO: Investigate on inconsistency results on CI, sometimes the hash generated is different for the slice 1-2 without apparent reason.
      Array.wrap(patterns).map { |pattern| Dir.glob(pattern) }
           .flatten
           .sort
           .each_with_object({}) do |file, result|
        next unless File.file?(file)

        result[file] = digest(File.read(file))
      end
    end

    private

    def digest(value)
      Digest::SHA256.hexdigest(value)
    end
  end
end
