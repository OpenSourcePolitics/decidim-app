# frozen_string_literal: true

# This migration comes from decidim_cleaner (originally 20230110150032)

class AddDeleteInactiveUsersToOrganization < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_organizations, :delete_inactive_users, :boolean, default: false, null: false
    add_column :decidim_organizations, :delete_inactive_users_email_after, :integer
    add_column :decidim_organizations, :delete_inactive_users_after, :integer
  end
end
