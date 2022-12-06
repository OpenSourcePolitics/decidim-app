# frozen_string_literal: true

module Decidim
  class RSpecRunner
    def initialize(pattern, mask, slice)
      @pattern = pattern
      @mask = mask
      @slice = parsed_slice(slice).first
      @total = parsed_slice(slice).last
    end

    def self.for(pattern = nil, mask = nil, slice = nil)
      raise "Missing pattern" unless pattern
      raise "Missing mask" unless mask
      raise "Missing slice" unless slice

      new(pattern, mask, slice).run
    end

    def run
      exec("bundle exec rspec #{sliced_files.join(" ")}")
    end

    def sliced_files
      all_files[@slice]
    end

    def all_files
      Dir.glob(@mask)
         .in_groups(@total, false)
    end

    private

    def parsed_slice(slice)
      slice.split("-").map(&:to_i)
    end
  end
end
