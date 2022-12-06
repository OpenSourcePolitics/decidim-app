# frozen_string_literal: true

module Decidim
  class RSpecRunner
    DEFAULT_PATTERN = "spec/**/*_spec.rb"

    def initialize(pattern, mask, slice)
      @pattern = pattern
      @mask = mask
      @slice, @total = parsed_slice(slice)
    end

    def self.for(pattern = nil, mask = nil, slice = nil)
      raise "Missing pattern" unless pattern
      raise "Missing mask" unless mask
      raise "Missing slice" unless slice

      new(pattern, mask, slice).run
    end

    def run
      logger.info("Running tests for slice #{@slice} of #{@total} slices")
      logger.info("Running tests for files: #{sliced_files.join(", ")}")
      exec("bundle exec rspec #{sliced_files.join(" ")}")
    end

    def sliced_files
      all_files.in_groups(@total, false)[@slice]
    end

    def all_files
      return Dir.glob(@mask) if @pattern == "include"

      default_files - Dir.glob(@mask)
    end

    def default_files
      Dir.glob(DEFAULT_PATTERN)
    end

    private

    def parsed_slice(slice)
      slice.split("-").map(&:to_i)
    end

    def logger
      Logger.new($stdout)
    end
  end
end
