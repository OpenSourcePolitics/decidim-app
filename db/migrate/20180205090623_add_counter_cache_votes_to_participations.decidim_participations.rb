# This migration comes from decidim_participations (originally 20170118120151)
# frozen_string_literal: true

class AddCounterCacheVotesToParticipations < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_participations_participations, :participation_votes_count, :integer, null: false, default: 0
  end
end
