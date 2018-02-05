# This migration comes from decidim_participations (originally 20170112115253)
# frozen_string_literal: true

class CreateParticipationVotes < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_participations_participation_votes do |t|
      t.references :decidim_participation, null: false, index: { name: "decidim_participations_vote_participation" }
      t.references :decidim_author, null: false, index: { name: "decidim_participations_vote_author" }

      t.timestamps
    end

    add_index :decidim_participations_participation_votes, [:decidim_participation_id, :decidim_author_id], unique: true, name: "decidim_participations_vote_participation_author_unique"
  end
end
