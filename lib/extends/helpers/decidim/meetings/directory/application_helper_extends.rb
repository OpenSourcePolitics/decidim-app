# frozen_string_literal: true

require "active_support/concern"
module ApplicationHelperExtends
  extend ActiveSupport::Concern
  include Decidim::CheckBoxesTreeHelper

  included do
    def directory_filter_scopes_values
      main_scopes = current_organization.scopes.top_level
      scopes_values = main_scopes.includes(:scope_type, :children).sort_by(&:weight).flat_map do |scope|
        TreeNode.new(
          TreePoint.new(scope.id.to_s, translated_attribute(scope.name, current_organization)),
          scope_children_to_tree(scope)
        )
      end

      scopes_values.prepend(TreePoint.new("global", t("decidim.scopes.global")))

      TreeNode.new(
        TreePoint.new("", t("decidim.meetings.application_helper.filter_scope_values.all")),
        scopes_values
      )
    end

    def scope_children_to_tree(scope)
      return unless scope.children.any?

      scope.children.includes(:scope_type, :children).sort_by(&:weight).flat_map do |child|
        TreeNode.new(
          TreePoint.new(child.id.to_s, translated_attribute(child.name, current_organization)),
          scope_children_to_tree(child)
        )
      end
    end
  end
end

Decidim::Meetings::Directory::ApplicationHelper.include(ApplicationHelperExtends)
