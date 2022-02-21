# frozen_string_literal: true
# This migration comes from decidim_homepage_interactive_map (originally 20200103153409)

class AddGeolocationToParticipatoryProcesses < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_participatory_processes, :address, :string
    add_column :decidim_participatory_processes, :latitude, :float
    add_column :decidim_participatory_processes, :longitude, :float
  end
end
