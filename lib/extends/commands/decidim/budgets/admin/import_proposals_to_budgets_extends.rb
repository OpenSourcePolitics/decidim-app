# frozen_string_literal: true

require "active_support/concern"

module ImportProposalsToBudgetsExtends
  extend ActiveSupport::Concern

  included do
    private

    def selected_scope_id
      params.dig("proposals_import", "scope_id")&.to_i
    end

    def proposals
      if selected_scope_id.present?
        children = Decidim::Scope.find(selected_scope_id).children
        children.present? ? all_proposals.where(decidim_scope_id: children.ids.push(selected_scope_id)) : all_proposals.where(decidim_scope_id: selected_scope_id)
      else
        all_proposals
      end
    end
  end
end

Decidim::Budgets::Admin::ImportProposalsToBudgets.include(ImportProposalsToBudgetsExtends)
