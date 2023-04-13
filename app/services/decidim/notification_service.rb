# frozen_string_literal: true

module Decidim
  class NotificationService < DatabaseService
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
