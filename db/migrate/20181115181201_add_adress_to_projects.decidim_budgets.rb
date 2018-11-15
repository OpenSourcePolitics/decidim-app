# frozen_string_literal: true
# This migration comes from decidim_budgets (originally 20180604135346)

class AddAdressToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_budgets_projects, :address, :string
    add_column :decidim_budgets_projects, :latitude, :float
    add_column :decidim_budgets_projects, :longitude, :float
  end
end
