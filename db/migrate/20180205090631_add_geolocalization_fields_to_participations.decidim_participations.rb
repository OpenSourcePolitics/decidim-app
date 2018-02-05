# This migration comes from decidim_participations (originally 20170228105156)
# frozen_string_literal: true

class AddGeolocalizationFieldsToParticipations < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_participations_participations, :address, :text
    add_column :decidim_participations_participations, :latitude, :float
    add_column :decidim_participations_participations, :longitude, :float
  end
end
