# frozen_string_literal: true
# This migration comes from decidim_ludens (originally 20230315112752)

class DeleteLudensColumnsFromOrganizations < ActiveRecord::Migration[6.0]
  def up
    remove_column :decidim_organizations, :assistant
    remove_column :decidim_organizations, :enable_ludens
  end

  def down
    add_column :decidim_organizations, :assistant, :jsonb
    add_column :decidim_organizations, :enable_ludens, :boolean, default: false
  end
end
