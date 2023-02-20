# frozen_string_literal: true

require "digest"

module Decidim
  class AssetsHash
    def initialize(options = {})
      @assets_patterns = %w(Gemfile* package* yarn* app/assets/**/* app/packs/**/* vendor/**/* packages/**/* lib/assets/**/*)
      @included_extensions = %w(lock Gemfile gemspec json js mjs jsx ts tsx gql graphql bmp gif jpeg jpg png tiff ico avif webp eot otf ttf woff woff2 svg md odt)
      @output = options.fetch("output", true)
      @output_path = options.fetch("output_path", "tmp/assets_manifest.json")
    end

    def self.run(options = {})
      new(options).run
    end

    def run
      assets_manifest = JSON.pretty_generate(files_digest(@assets_patterns))

      File.write(@output_path, assets_manifest) if @output

      digest(assets_manifest)
    end

    def files_digest(patterns)
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
