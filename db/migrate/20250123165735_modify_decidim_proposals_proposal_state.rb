class ModifyDecidimProposalsProposalState < ActiveRecord::Migration[7.0]
  def up
    add_column :decidim_proposals_proposal_states, :bg_color, :string, default: "#F6F8FA", null: false, if_not_exists: true
    add_column :decidim_proposals_proposal_states, :text_color, :string, default: "#4B5058", null: false, if_not_exists: true
  end
end
