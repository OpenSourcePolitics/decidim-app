# frozen_string_literal: true

# This migration comes from decidim_geo (originally 20241019233857)
class AddVectorLayerConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_geo_configs, :maptiler_api_key, :string, default: ""
    add_column :decidim_geo_configs, :maptiler_style_id, :string, default: ""
  end
end
