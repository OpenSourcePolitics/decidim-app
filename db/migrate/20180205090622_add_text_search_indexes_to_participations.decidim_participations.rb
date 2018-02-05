# This migration comes from decidim_participations (originally 20170113114245)
# frozen_string_literal: true

class AddTextSearchIndexesToParticipations < ActiveRecord::Migration[5.0]
  def change
    add_index :decidim_participations_participations, :title, name: "decidim_participations_participation_title_search"
    add_index :decidim_participations_participations, :body, name: "decidim_participations_participation_body_search"
  end
end
