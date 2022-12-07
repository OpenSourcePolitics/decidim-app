# frozen_string_literal: true

require "digest"

module Decidim
  class AssetsHash
    def initialize
      @yarn_hash = yarn_hash
      @app_assets_hash = app_assets_hash
      @app_dependencies_hash = app_dependencies_hash
    end

    def self.run
      new.run
    end

    def run
      Digest::SHA256.hexdigest("#{@app_assets_hash}#{@yarn_hash}#{@app_dependencies_hash}")
    end

    private

    def app_dependencies_hash
      hash(app_dependencies_files)
    end

    def app_dependencies_files
      files_cat(Bundler.load.specs
                       .map(&:full_gem_path)
                       .map { |path| assets_pattern.map { |pattern| "#{path}/#{pattern}" } }
                       .flatten)
    end

    def app_assets_hash
      hash(app_assets_files)
    end

    def app_assets_files
      files_cat(assets_pattern)
    end

    def assets_pattern
      ["app/assets/**/*", "app/packs/**/*", "vendor/**/*"]
    end

    def yarn_hash
      hash(yarn_files)
    end

    def yarn_files
      files_cat("**/yarn.lock")
    end

    def hash(value)
      Digest::SHA256.hexdigest(value)
    end

    def files_cat(*files)
      files.map { |pattern| Dir.glob(pattern) }
           .flatten
           .select { |file| File.file?(file) }
           .map(&File.method(:read))
           .join
    end
  end
end
