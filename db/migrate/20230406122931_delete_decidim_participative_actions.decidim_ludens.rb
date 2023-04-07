# frozen_string_literal: true

# This migration comes from decidim_ludens (originally 20230315112940)

class DeleteDecidimParticipativeActions < ActiveRecord::Migration[6.0]
  def change
    drop_table :decidim_participative_actions
  end
end
