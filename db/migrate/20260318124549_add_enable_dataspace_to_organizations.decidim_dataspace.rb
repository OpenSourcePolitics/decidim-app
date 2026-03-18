# frozen_string_literal: true

# This migration comes from decidim_dataspace (originally 20260129143027)
class AddEnableDataspaceToOrganizations < ActiveRecord::Migration[7.0]
  def up
    add_column :decidim_organizations, :enable_dataspace, :boolean, default: false, null: false
  end

  def down
    remove_column :decidim_organizations, :enable_dataspace
  end
end
