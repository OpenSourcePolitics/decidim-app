# This migration comes from decidim_assemblies (originally 20190201235001)
class AddHostnameToAssemblies < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_assemblies, :hostname, :string
    add_index :decidim_assemblies, :hostname, unique: true
  end
end
