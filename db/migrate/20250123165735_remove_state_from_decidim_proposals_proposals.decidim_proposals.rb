# frozen_string_literal: true

# This migration comes from decidim_proposals (originally 20240110203503)
class RemoveStateFromDecidimProposalsProposals < ActiveRecord::Migration[6.1]
  def up
    if column_exists?(:decidim_proposals_proposal_states, :state)
      rename_column :decidim_proposals_proposals, :state, :old_state
    end
  end

  def down
    rename_column :decidim_proposals_proposals, :old_state, :state
  end
end
