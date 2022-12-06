# frozen_string_literal: true

module Decidim
  class RSpecRunner
    def initialize(pattern, slice)
      @pattern = pattern
      @slice = parsed_slice(slice).first
      @total = parsed_slice(slice).last
    end

    def self.for(pattern = nil, slice = nil)
      raise "Missing pattern" unless pattern
      raise "Missing slice" unless slice

      new(pattern, slice).run
    end

    def run
      files = Dir.glob(@pattern)
                 .in_groups(@total)[@slice]
                 .compact
                 .join(" ")

      exec("bundle exec rspec #{files}")
    end

    private

    def parsed_slice(slice)
      slice.split("-").map(&:to_i)
    end
  end
end
