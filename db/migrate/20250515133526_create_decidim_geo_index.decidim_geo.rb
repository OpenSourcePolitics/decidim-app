# frozen_string_literal: true

# This migration comes from decidim_geo (originally 20240926122427)
class CreateDecidimGeoIndex < ActiveRecord::Migration[6.1]
  def change
    create_table :decidim_geo_indexes do |t|
      t.jsonb :title, null: false
      t.jsonb :short_description
      t.jsonb :description_html
      t.string :image_url
      t.boolean :avoid_index, default: false, null: false
      t.jsonb :extended_data
      t.integer :component_id
      t.string :participatory_space_type, null: false
      t.integer :participatory_space_id, null: false
      t.integer :resource_id, null: false
      t.string :resource_type, null: false
      t.string :resource_url, null: false
      t.string :resource_status
      t.st_point :lonlat, geographic: true

      t.references :geo_scope, foreign_key: { to_table: :decidim_scopes }
      t.date :start_date
      t.date :end_date
      t.timestamps

      # Indexes for faster search
      t.index :start_date
      t.index :end_date

      t.index [:resource_type, :resource_id], unique: true, name: "decidim_geo_indx_resource"
    end
  end
end
