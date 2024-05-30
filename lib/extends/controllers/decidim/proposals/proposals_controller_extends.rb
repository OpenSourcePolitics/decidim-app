# frozen_string_literal: true

require "active_support/concern"
module ProposalsControllerExtends
  extend ActiveSupport::Concern
  included do
    private

    def default_filter_scope_params
      return "all" unless current_component.scopes.any?

      if (scope = current_component.scope)
        scope_children = scope.children
        scope_children_ids = scope_children.present? ? scope_children.map(&:id) : []
        ids = ["all", scope.id] + scope_children_ids
        while Decidim::Scope.where(parent_id: scope_children_ids).present?
          sub_ids = Decidim::Scope.where(parent_id: scope_children_ids).pluck(:id)
          ids += sub_ids
          scope_children_ids = sub_ids
        end
        ids.map(&:to_s)
      else
        %w(all global) + current_component.scopes.pluck(:id).map(&:to_s)
      end
    end
  end
end

Decidim::Proposals::ProposalsController.include(ProposalsControllerExtends)
