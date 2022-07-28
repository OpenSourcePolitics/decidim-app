# frozen_string_literal: true
# This migration comes from decidim_ludens (originally 20221229155731)

class AddAssistantToOrganization < ActiveRecord::Migration[6.0]
  def up
    add_column :decidim_organizations, :assistant, :jsonb
  end

  def down
    remove_column :decidim_organizations, :assistant
  end
end
