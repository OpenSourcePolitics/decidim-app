# frozen_string_literal: true
# This migration comes from decidim_custom_proposal_states (originally 20231102173214)

class AddStateIdToDecidimProposalsProposals < ActiveRecord::Migration[6.0]
  def up
    add_column :decidim_proposals_proposals, :decidim_proposals_proposal_state_id, :integer, index: true

    add_foreign_key :decidim_proposals_proposals, :decidim_proposals_proposal_states, column: :decidim_proposals_proposal_state_id
  end

  def down
    remove_foreign_key :decidim_proposals_proposals, column: :decidim_proposals_proposal_state_id
    remove_column :decidim_proposals_proposals, :decidim_proposals_proposal_state_id
  end
end
