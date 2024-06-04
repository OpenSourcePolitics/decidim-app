# frozen_string_literal: true

require "active_support/concern"
module ProposalsControllerExtends
  extend ActiveSupport::Concern
  included do
    private

    def default_filter_scope_params
      return "all" unless current_component.scopes.any?

      scope = current_component.scope
      return current_component_scope_ids if scope.blank?

      scope_children_ids = scope.children&.map(&:id)
      ids = ["all", scope.id] + scope_children_ids
      while Decidim::Scope.where(parent_id: scope_children_ids).present?
        sub_ids = Decidim::Scope.where(parent_id: scope_children_ids).pluck(:id)
        ids += sub_ids
        scope_children_ids = sub_ids
      end
      ids.map(&:to_s)
    end

    def current_component_scope_ids
      component_scopes = current_component.scopes.pluck(:id).map(&:to_s)
      %w(all global) + component_scopes
    end
  end
end

Decidim::Proposals::ProposalsController.include(ProposalsControllerExtends)
