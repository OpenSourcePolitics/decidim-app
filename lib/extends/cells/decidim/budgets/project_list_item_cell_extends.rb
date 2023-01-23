# frozen_string_literal: true

module ProjectListItemCellExtends
  def cache_hash
    hash = []
    hash.push(model.id)
    hash.push(resource_title)
    hash.push(model.budget_amount)
    hash.push(model&.category.try(:id))
    hash.push(resource_added?)
    hash.push(can_have_order?)
    hash.join(Decidim.cache_key_separator)
  end
end

Decidim::Budgets::ProjectListItemCell.class_eval do
  prepend(ProjectListItemCellExtends)
end
