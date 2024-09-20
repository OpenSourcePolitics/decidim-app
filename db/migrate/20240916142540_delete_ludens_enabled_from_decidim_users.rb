class DeleteLudensEnabledFromDecidimUsers < ActiveRecord::Migration[6.1]
  def up
    remove_column :decidim_users, :enable_ludens
  end

  def down
    add_column :decidim_users, :enable_ludens, :boolean
  end
end
