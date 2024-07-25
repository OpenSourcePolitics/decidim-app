# frozen_string_literal: true
# This migration comes from decidim_geo (originally 20221019184712)

class AddPostgisExtensionToDatabase < ActiveRecord::Migration[6.0]
  def change
    enable_extension "postgis"
  end
end
