# frozen_string_literal: true

# This migration comes from decidim_geo (originally 20241016062634)
class AddFocusZoomLevelConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_geo_configs, :focus_zoom_level, :integer, default: 21
  end
end
