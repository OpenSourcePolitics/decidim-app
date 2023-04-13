# frozen_string_literal: true

module Decidim
  class DatabaseService
    def initialize(**args)
      @verbose = args[:verbose] || false
      @logger = args[:logger] || Logger.new($stdout)
    end

    def orphans
      raise NotImpletedError
    end

    def clear
      raise NotImpletedError
    end

    private

    def resource_types
      raise NotImpletedError
    end

    def orphans_for(_klass)
      raise NotImpletedError
    end

    def clear_data_for(_klass)
      raise NotImpletedError
    end

    def orphans_count_for(klass)
      orphans_for(klass).count
    end
  end
end
