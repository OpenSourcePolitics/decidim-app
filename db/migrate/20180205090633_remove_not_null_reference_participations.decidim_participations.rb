# This migration comes from decidim_participations (originally 20170410073742)
# frozen_string_literal: true

class RemoveNotNullReferenceParticipations < ActiveRecord::Migration[5.0]
  def change
    change_column_null :decidim_participations_participations, :reference, true
  end
end
