# frozen_string_literal: true

# This migration comes from decidim_cleaner (originally 20230106105014)

class AddDeleteAdminLogsToOrganization < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_organizations, :delete_admin_logs, :boolean, default: false, null: false
    add_column :decidim_organizations, :delete_admin_logs_after, :integer
  end
end
