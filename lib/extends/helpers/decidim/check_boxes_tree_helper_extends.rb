# frozen_string_literal: true

module CheckBoxesTreeHelperExtends
  def filter_scopes_values
    return filter_scopes_values_from_parent(current_component.scope) if current_component.scope.present?

    main_scopes = current_participatory_space.scopes.top_level
                                             .includes(:scope_type, :children)
                                             .sort_by(&:weight)
    filter_scopes_values_from(main_scopes)
  end

  def filter_scopes_values_from_parent(scope)
    scopes_values = []
    scope.children.sort_by(&:weight).each do |child|
      unless child.children
        scopes_values << Decidim::CheckBoxesTreeHelper::TreePoint.new(child.id.to_s, translated_attribute(child.name, current_participatory_space.organization))
        next
      end
      scopes_values << Decidim::CheckBoxesTreeHelper::TreeNode.new(
        Decidim::CheckBoxesTreeHelper::TreePoint.new(child.id.to_s, translated_attribute(child.name, current_participatory_space.organization)),
        scope_children_to_tree(child)
      )
    end

    filter_tree_from(scopes_values)
  end

  def filter_scopes_values_from(scopes, participatory_space = nil)
    scopes_values = scopes.compact.sort_by(&:weight).flat_map do |scope|
      Decidim::CheckBoxesTreeHelper::TreeNode.new(
        Decidim::CheckBoxesTreeHelper::TreePoint.new(scope.id.to_s, translated_attribute(scope.name)),
        scope_children_to_tree(scope)
      )
    end

    scopes_values.prepend(Decidim::CheckBoxesTreeHelper::TreePoint.new("global", t("decidim.scopes.global"))) if participatory_space&.scope.blank?

    filter_tree_from(scopes_values)
  end

  def scope_children_to_tree(scope, participatory_space = nil)
    return if participatory_space.present? && scope.scope_type && scope.scope_type == current_participatory_space.try(:scope_type_max_depth)
    return unless scope.children.any?

    sorted_children = scope.children.includes(:scope_type, :children).sort_by(&:weight)

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
