# frozen_string_literal: true

# This migration comes from decidim (originally 20181214101250)

class AddNotificationTypesToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_users, :notification_types, :string, default: "all"
    Decidim::UserBaseEntity.update_all(notification_types: "all")
    change_column_null :decidim_users, :notification_types, false
  end
end
