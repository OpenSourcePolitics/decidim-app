# frozen_string_literal: true

require "active_support/concern"

module ScopesControllerExtends
  extend ActiveSupport::Concern
  included do
    def picker
      enforce_permission_to :pick, :scope

      context = picker_context(root, title, max_depth)
      required = params&.[](:required) != "false"

      scopes, parent_scopes = resolve_picker_scopes(root, current)

      render(
        :picker,
        layout: nil,
        locals: {
          required:,
          title:,
          root:,
          current: (current || root),
          scopes: scopes&.sort_by(&:weight),
          parent_scopes: parent_scopes.sort_by(&:weight),
          picker_target_id: (params[:target_element_id] || "content"),
          global_value: params[:global_value],
          max_depth:,
          context:
        }
      )
    end
  end
end

Decidim::ScopesController.include(ScopesControllerExtends)
