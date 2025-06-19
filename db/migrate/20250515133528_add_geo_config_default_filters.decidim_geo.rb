# frozen_string_literal: true

# This migration comes from decidim_geo (originally 20241014122841)
class AddGeoConfigDefaultFilters < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_geo_configs, :default_geoencoded_filter, :integer, default: 0
  end
end
