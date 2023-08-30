# frozen_string_literal: true
# This migration comes from decidim_extra_user_fields (originally 20221024121407)

class AddExtraUserFieldsToDecidimOrganization < ActiveRecord::Migration[6.0]
  def up
    add_column :decidim_organizations, :extra_user_fields, :jsonb, default: { "enabled" => false }
  end

  def down
    remove_column :decidim_organizations, :extra_user_fields, :jsonb
  end
end
