# frozen_string_literal: true
# This migration comes from decidim_initiatives (originally 20181003082010)

class FixUserGroupsIdsOnInitiatives < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/SkipsModelValidations
  def change
    return unless defined?(Decidim::Initiative)

    Decidim::UserGroup.find_each do |group|
      old_id = group.extended_data["old_user_group_id"]
      next unless old_id

      Decidim::Initiative
        .where(decidim_user_group_id: old_id)
        .update_all(decidim_user_group_id: group.id)
      Decidim::InitiativesVote
        .where(decidim_user_group_id: old_id)
        .update_all(decidim_user_group_id: group.id)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
