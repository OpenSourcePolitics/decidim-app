# frozen_string_literal: true

require "digest"

module Decidim
  class AssetsHash
    def initialize
      @assets_patterns = %w(Gemfile Gemfile.lock package.json yarn.lock app/assets/**/* app/packs/**/* vendor/**/* packages/**/* lib/assets/**/*)
      @included_extensions = %w(lock Gemfile gemspec json js mjs jsx ts tsx gql graphql bmp gif jpeg jpg png tiff ico avif webp eot otf ttf woff woff2 svg md odt)
    end

    def self.run(output: true)
      new.run(output)
    end

    def run(output)
      assets_manifest = JSON.pretty_generate(files_digest(@assets_patterns))

      File.write("tmp/assets_manifest.json", assets_manifest) if output

      digest(assets_manifest)
    end

    def files_digest(patterns)
      # TODO: Investigate on inconsistency results on CI, sometimes the hash generated is different for the slice 1-2 without apparent reason.
      patterns.map { |pattern| Dir.glob(pattern) }
              .flatten
              .sort
              .each_with_object({}) do |file, result|
        next unless File.file?(file)
        next unless @included_extensions.any? { |ext| file.end_with?(ext) }

        result[file] = digest(File.read(file))
      end
    end

    private

    def digest(value)
      Digest::SHA256.hexdigest(value)
    end
  end
end
