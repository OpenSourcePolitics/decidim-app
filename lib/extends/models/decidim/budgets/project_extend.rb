# frozen_string_literal: true

require "active_support/concern"
module ProjectExtends
  extend ActiveSupport::Concern

  included do
    delegate :visible?, to: :budget

      searchable_fields({
                          scope_id: :decidim_scope_id,
                          participatory_space: { component: :participatory_space },
                          A: :title,
                          D: :description,
                          datetime: :created_at
                        },
                        index_on_create: ->(project) { project.visible? },
                        index_on_update: ->(project) { project.visible? })
    def self.ordered_ids(ids)
      # Make sure each ID in the matching text has a "," character as their
      # delimiter. Otherwise e.g. ID 2 would match ID "26" in the original
      # array. This is why we search for match ",2," instead to get the actual
      # position for ID 2.
      concat_ids = connection.quote(",#{ids.join(",")},")
      order(Arel.sql("position(concat(',', decidim_budgets_projects.id::text, ',') in #{concat_ids})"))
    end
  end
end

Decidim::Budgets::Project.include(ProjectExtends)
