# frozen_string_literal: true

# This migration comes from decidim_budgets_booth (originally 20230301155948)

class AddMainImageToDecidimBudgetsBudgets < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_budgets_budgets, :main_image, :string
  end
end
