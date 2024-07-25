# frozen_string_literal: true
# This migration comes from decidim_geo (originally 20231013082325)

# This migration comes from decidim_geo (originally 20231012094655)
class CreateDecidimGeoConfig < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_geo_configs do |t|
      t.float :longitude, null: true
      t.float :latitude, null: true
      t.integer :zoom, null: true
      t.string :tile, null: true
    end
  end
end
