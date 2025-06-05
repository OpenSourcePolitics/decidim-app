class UpdateNullableOnDecidimProposalsProposalStateId < ActiveRecord::Migration[7.0]
  def change
    change_column_null :decidim_proposals_proposals, :decidim_proposals_proposal_state_id, true
  end
end
