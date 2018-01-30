# This migration comes from decidim_participations (originally 20170307085300)
# frozen_string_literal: true

class MigrateParticipationReportsDataToReports < ActiveRecord::Migration[5.0]
  class Decidim::Participations::ParticipationReport < ApplicationRecord
    belongs_to :user, foreign_key: "decidim_user_id", class_name: "Decidim::User"
    belongs_to :participation, foreign_key: "decidim_participation_id", class_name: "Decidim::Participations::Participation"
  end

  def change
    Decidim::Participations::ParticipationReport.find_each do |participation_report|
      moderation = Decidim::Moderation.find_or_create_by!(reportable: participation_report.participation,
                                                          participatory_process: participation_report.participation.feature.participatory_space)
      Decidim::Report.create!(moderation: moderation,
                              user: participation_report.user,
                              reason: participation_report.reason,
                              details: participation_report.details)
      moderation.update_attributes!(report_count: moderation.report_count + 1)
    end

    drop_table :decidim_participations_participation_reports
    remove_column :decidim_participations_participations, :report_count
    remove_column :decidim_participations_participations, :hidden_at
  end
end
