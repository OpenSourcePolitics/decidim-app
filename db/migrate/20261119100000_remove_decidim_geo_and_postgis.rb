# frozen_string_literal: true

# Decidim Geo was removed from the app (#847) but its tables, which use PostGIS
# column types, and the postgis extension were left in the database.
class RemoveDecidimGeoAndPostgis < ActiveRecord::Migration[7.0]
  def up
    drop_table :decidim_geo_shapefile_datas, if_exists: true
    drop_table :decidim_geo_shapefiles, if_exists: true
    drop_table :decidim_geo_indexes, if_exists: true
    drop_table :decidim_geo_no_indexes, if_exists: true
    drop_table :decidim_geo_space_locations, if_exists: true
    drop_table :decidim_geo_configs, if_exists: true

    execute "DROP EXTENSION IF EXISTS postgis"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
