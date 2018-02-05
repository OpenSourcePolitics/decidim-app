# This migration comes from decidim_participations (originally 20170120151202)
# frozen_string_literal: true

class AddUserGroupIdToParticipations < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_participations_participations, :decidim_user_group_id, :integer, index: true
  end
end
