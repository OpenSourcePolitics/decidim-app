# This migration comes from decidim_participations (originally 20170131092413)
# frozen_string_literal: true

class AddAnswersToParticipations < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_participations_participations, :state, :string, index: true
    add_column :decidim_participations_participations, :answered_at, :datetime, index: true
    add_column :decidim_participations_participations, :answer, :jsonb
  end
end
