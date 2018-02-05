# This migration comes from decidim_participations (originally 20170215131720)
# frozen_string_literal: true

class AddReportCountToParticipations < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_participations_participations, :report_count, :integer, default: 0
  end
end
