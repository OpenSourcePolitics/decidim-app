# This migration comes from decidim_participations (originally 20170220152416)
# frozen_string_literal: true

class AddHiddenAtToParticipations < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_participations_participations, :hidden_at, :datetime
  end
end
