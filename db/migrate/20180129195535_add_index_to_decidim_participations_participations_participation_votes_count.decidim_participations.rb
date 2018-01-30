# This migration comes from decidim_participations (originally 20170205082832)
# frozen_string_literal: true

class AddIndexToDecidimParticipationsParticipationsParticipationVotesCount < ActiveRecord::Migration[5.0]
  def change
    add_index :decidim_participations_participations, :participation_votes_count, name: "decidim_participations_votes_count"
    add_index :decidim_participations_participations, :created_at
    add_index :decidim_participations_participations, :state
  end
end
