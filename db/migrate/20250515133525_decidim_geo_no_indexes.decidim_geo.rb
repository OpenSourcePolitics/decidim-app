# frozen_string_literal: true

# This migration comes from decidim_geo (originally 20240923091022)
class DecidimGeoNoIndexes < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_geo_no_indexes do |t|
      t.boolean :no_index, default: false, null: false
      t.integer :decidim_component_id
      t.string :decidim_component_type
      t.timestamps
    end

    add_index :decidim_geo_no_indexes,
              [:decidim_component_id],
              unique: true,
              name: "decidim_geo_uniq_no_index"
  end
end
