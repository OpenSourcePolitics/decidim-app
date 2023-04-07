# frozen_string_literal: true

# This migration comes from decidim_ludens (originally 20230315113349)

class CreateDecidimParticipativeActionsCompletedTable < ActiveRecord::Migration[6.0]
  def change
    create_table :participative_actions_completed do |t|
      t.string :decidim_participative_action, null: false
      t.references :decidim_user, null: false, foreign_key: true
    end
  end
end
