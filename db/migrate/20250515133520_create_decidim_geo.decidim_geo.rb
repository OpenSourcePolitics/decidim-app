# frozen_string_literal: true

# This migration comes from decidim_geo (originally 20221025195520)
class CreateDecidimGeo < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_geo_shapefiles do |t|
      t.string :title, null: false
      t.string :description, null: true
      t.string :shapefile, null: false
      t.belongs_to :decidim_scope_types, index: true, foreign_key: true, null: true

      t.timestamps
    end

    create_table :decidim_geo_shapefile_datas do |t|
      t.belongs_to :decidim_geo_shapefiles, index: true, foreign_key: true
      t.jsonb :data
      t.multi_polygon :geom

      t.belongs_to :decidim_scopes, index: true, foreign_key: true, null: true

      t.timestamps
    end
  end
end
