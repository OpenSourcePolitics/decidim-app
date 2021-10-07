# frozen_string_literal: true

# This migration comes from decidim_budgets (originally 20180604135346)

class AddAdressToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_budgets_projects, :address, :string unless column_exists?(:decidim_budgets_projects, :address)
    add_column :decidim_budgets_projects, :latitude, :float unless column_exists?(:decidim_budgets_projects, :latitude)
    add_column :decidim_budgets_projects, :longitude, :float unless column_exists?(:decidim_budgets_projects, :longitude)
  end
end
