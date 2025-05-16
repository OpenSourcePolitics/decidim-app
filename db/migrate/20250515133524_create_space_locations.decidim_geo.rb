# frozen_string_literal: true

# This migration comes from decidim_geo (originally 20240326052727)
class CreateSpaceLocations < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_geo_space_locations do |t|
      t.bigint :decidim_geo_space_id
      t.string :decidim_geo_space_type
      t.string :address
      t.float :latitude
      t.float :longitude
      t.timestamps
    end

    add_index :decidim_geo_space_locations,
              [:decidim_geo_space_type, :decidim_geo_space_id],
              unique: true,
              name: "decidim_geo_space_poly_idx"
  end
end
