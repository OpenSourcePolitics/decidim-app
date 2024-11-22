class AddWeightToScopes < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_scopes, :weight, :integer, default: 0
  end
end