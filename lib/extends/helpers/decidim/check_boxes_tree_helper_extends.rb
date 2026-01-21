# frozen_string_literal: true

module CheckBoxesTreeHelperExtends
  def filter_areas_values
    areas_or_types = areas_for_select(current_organization)

    areas_values = if areas_or_types.first.is_a?(Decidim::Area)
                     filter_areas(areas_or_types)
                   else
                     filter_areas_and_types(areas_or_types)
                   end
    return if areas_values.blank?

    Decidim::CheckBoxesTreeHelper::TreeNode.new(
      Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.core.application_helper.filter_area_values.all")),
      areas_values
    )
  end

  def filter_global_scopes_values
    scopes = current_organization.scopes.top_level.includes(:scope_type, :children)
    filter_scopes_values_from(scopes)
  end

  def filter_scopes_values_from(scopes, participatory_space = nil)
    scopes_values = scopes.compact.sort_by { |scope| scope.weight || 0 }.flat_map do |scope|
      Decidim::CheckBoxesTreeHelper::TreeNode.new(
        Decidim::CheckBoxesTreeHelper::TreePoint.new(scope.id.to_s, translated_attribute(scope.name)),
        scope_children_to_tree(scope, participatory_space)
      )
    end

    if participatory_space&.scope.blank?
      scopes_values.prepend(
        Decidim::CheckBoxesTreeHelper::TreePoint.new("global", t("decidim.scopes.global"))
      )
    end

    filter_tree_from(scopes_values)
  end

  def scope_children_to_tree(scope, participatory_space = nil)
    return if participatory_space.present? && scope.scope_type && scope.scope_type == current_participatory_space.try(:scope_type_max_depth)
    return unless scope.children.any?

    sorted_children = scope.children.includes(:scope_type, :children).sort_by { |child| child.weight || 0 }

    sorted_children.flat_map do |child|
      Decidim::CheckBoxesTreeHelper::TreeNode.new(
        Decidim::CheckBoxesTreeHelper::TreePoint.new(child.id.to_s, translated_attribute(child.name)),
        scope_children_to_tree(child, participatory_space)
      )
    end
  end
end

Decidim::CheckBoxesTreeHelper.module_eval do
  prepend(CheckBoxesTreeHelperExtends)
end
