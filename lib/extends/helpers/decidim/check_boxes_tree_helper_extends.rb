# frozen_string_literal: true

module CheckBoxesTreeHelperExtends
  def filter_categories_values
    sorted_main_categories = current_participatory_space.categories.first_class.includes(:subcategories).sort_by do |category|
      [category.weight, translated_attribute(category.name)]
    end

    categories_values = sorted_main_categories.flat_map do |category|
      sorted_descendant_categories = category.descendants.includes(:subcategories).sort_by do |subcategory|
        [subcategory.weight, translated_attribute(subcategory.name)]
      end

      subcategories = sorted_descendant_categories.flat_map do |subcategory|
        Decidim::CheckBoxesTreeHelper::TreePoint.new(subcategory.id.to_s, translated_attribute(subcategory.name))
      end

      Decidim::CheckBoxesTreeHelper::TreeNode.new(
        Decidim::CheckBoxesTreeHelper::TreePoint.new(category.id.to_s, translated_attribute(category.name)),
        subcategories
      )
    end

    Decidim::CheckBoxesTreeHelper::TreeNode.new(
      Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.core.application_helper.filter_category_values.all")),
      categories_values
    )
  end

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
