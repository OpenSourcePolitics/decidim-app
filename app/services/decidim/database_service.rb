# frozen_string_literal: true

module Decidim
  class DatabaseService
    def initialize(**args)
      @verbose = args[:verbose] || false
      @logger = args[:logger] || Logger.new($stdout)
    end

    def orphans
      if resource_types.blank?
        @logger.info "No resource_types found, terminating..." if @verbose
        return
      end

      @logger.info "Finding orphans rows in database for #{resource_types.join(", ")} ..." if @verbose

      orphans = {}
      resource_types.each do |klass|
        current_orphans_h = { klass => orphans_count_for(klass) }
        orphans.merge!(current_orphans_h)
        @logger.info current_orphans_h if @verbose
      end

      orphans
    end

    def clear
      @logger.info "Removing orphans rows in database for #{resource_types.join(", ")} ..." if @verbose

      resource_types.each do |klass|
        removed = clear_data_for(klass)
        @logger.info({ klass => removed.size }) if @verbose
      end
    end

    private

    def resource_types
      raise "Method resource_types isn't defined for #{self.class}"
    end

    def orphans_for(_klass)
      raise "Method orphans_for isn't defined for #{self.class}"
    end

    def clear_data_for(_klass)
      raise "Method clear_data_for isn't defined for #{self.class}"
    end

    def orphans_count_for(klass)
      orphans_for(klass).count
    end
  end
end
