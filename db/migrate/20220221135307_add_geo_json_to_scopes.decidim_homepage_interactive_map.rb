# frozen_string_literal: true
# This migration comes from decidim_homepage_interactive_map (originally 20191125143402)

class AddGeoJsonToScopes < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_scopes, :geojson, :jsonb
  end
end
