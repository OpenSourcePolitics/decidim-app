# frozen_string_literal: true

module Decidim
  class NotificationService < DatabaseService
    def orphans
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
      @resource_types ||= Decidim::Notification.distinct.pluck(:decidim_resource_type)
    end

    def orphans_for(klass)
      Decidim::Notification
        .where(decidim_resource_type: klass)
        .where.not(decidim_resource_id: [klass.constantize.ids])
        .pluck(:event_name, :decidim_resource_id, :extra)
    end

    def orphans_count_for(klass)
      orphans_for(klass).count
    end

    def clear_data_for(klass)
      Decidim::Notification.where(decidim_resource_type: klass).where.not(decidim_resource_id: [klass.constantize.ids]).destroy_all
    end
  end
end
