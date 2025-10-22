# frozen_string_literal: true

require "active_support/concern"

module ProjectsControllerExtends
  extend ActiveSupport::Concern
  included do
    def default_filter_params
      {
        search_text_cont: "",
        with_any_status: "all",
        with_any_scope: nil,
        with_any_category: nil,
        addition_type: "all"
      }
    end
  end
end

Decidim::Budgets::ProjectsController.include(ProjectsControllerExtends)
