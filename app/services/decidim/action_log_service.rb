# frozen_string_literal: true

module Decidim
  class ActionLogService < DatabaseService
    private

    def resource_types
      @resource_types ||= Decidim::ActionLog.distinct.pluck(:resource_type)
    end

    def orphans_for(klass)
      Decidim::ActionLog
        .where(resource_type: klass)
        .where.not(resource_id: [klass.constantize.ids])
        .pluck(:action, :resource_id, :extra)
    end

    def orphans_count_for(klass)
      orphans_for(klass).count
    end

    def clear_data_for(klass)
      actions = Decidim::ActionLog
                .where(resource_type: klass)
                .where.not(resource_id: [klass.constantize.ids])

      actions.delete_all
    end
  end
end
