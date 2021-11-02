# frozen_string_literal: true

# This migration comes from decidim_url_aliases (originally 20190820104806)

class AddOrganizationToRedirectRules < ActiveRecord::Migration[5.2]
  def change
    add_column :redirect_rules,
               :decidim_organization_id,
               :integer
  end
end
