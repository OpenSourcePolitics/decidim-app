# frozen_string_literal: true

require "active_support/concern"

module UserActivityCellExtends
  extend ActiveSupport::Concern

  included do
    def activities
      # filter from activities the deleted comments
      resource_ids_to_filter = context[:activities].select { |log| log[:action] == "delete" && log[:resource_type] == "Decidim::Comments::Comment" }.map(&:resource_id)
      if resource_ids_to_filter.any?
        context[:activities].where.not("resource_id in (?) AND resource_type = ?", resource_ids_to_filter, "Decidim::Comments::Comment")
      else
        context[:activities]
      end
    end
  end
end

Decidim::UserActivityCell.include(UserActivityCellExtends)
