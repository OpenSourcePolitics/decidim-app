# frozen_string_literal: true

# This migration comes from decidim_budgets_booth (originally 20241127162648)
class DeleteMainImageFromDecidimBudgetsBudgets < ActiveRecord::Migration[7.0]
  def up
    remove_column :decidim_budgets_budgets, :main_image
  end

  def down
    add_column :decidim_budgets_budgets, :main_image, :string
  end
end
