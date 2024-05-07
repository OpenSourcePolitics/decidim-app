require "active_support/concern"

module ImportProposalsToBudgetsExtends
  extend ActiveSupport::Concern

  included do
    private

    def proposals
      return all_proposals if form.scope_id.blank?

      children = Decidim::Scope.find(form.scope_id).children
      children.present? ? all_proposals.where(decidim_scope_id: children.ids.push(form.scope_id)) : all_proposals.where(decidim_scope_id: form.scope_id)
    end
  end
end

Decidim::Budgets::Admin::ImportProposalsToBudgets.include(ImportProposalsToBudgetsExtends)
