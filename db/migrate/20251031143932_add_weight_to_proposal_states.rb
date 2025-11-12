class AddWeightToProposalStates < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_proposals_proposal_states, :weight, :integer
  end
end
