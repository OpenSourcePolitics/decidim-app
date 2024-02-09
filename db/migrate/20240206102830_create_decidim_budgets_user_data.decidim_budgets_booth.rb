# frozen_string_literal: true

# This migration comes from decidim_budgets_booth (originally 20230303144938)

class CreateDecidimBudgetsUserData < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_budgets_user_data do |t|
      t.jsonb :metadata
      t.boolean :affirm_statements_are_correct, default: false
      t.references :decidim_component, null: false, indec: true
      t.references :decidim_user, null: false, index: true

      t.timestamps
    end

    add_index :decidim_budgets_user_data, [:decidim_component_id, :decidim_user_id], unique: true, name: "decidim_budgets_user_data_unique_user_and_component"
  end
end
