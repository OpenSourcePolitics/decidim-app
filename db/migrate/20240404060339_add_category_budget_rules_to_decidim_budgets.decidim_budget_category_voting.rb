# This migration comes from decidim_budget_category_voting (originally 20240224232551)
class AddCategoryBudgetRulesToDecidimBudgets < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_budgets_budgets, :category_budget_rules, :json, default: []
  end
end
