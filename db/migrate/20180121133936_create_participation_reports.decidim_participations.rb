# This migration comes from decidim_participations (originally 20170215113152)
# frozen_string_literal: true

class CreateParticipationReports < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_participations_participation_reports do |t|
      t.references :decidim_participation, null: false, index: { name: "decidim_participations_participation_result_participation" }
      t.references :decidim_user, null: false, index: { name: "decidim_participations_participation_result_user" }
      t.string :reason, null: false
      t.text :details

      t.timestamps
    end

    add_index :decidim_participations_participation_reports, [:decidim_participation_id, :decidim_user_id], unique: true, name: "decidim_participations_report_participation_user_unique"
  end
end
