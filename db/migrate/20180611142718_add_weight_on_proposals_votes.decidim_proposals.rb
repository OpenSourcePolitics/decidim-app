# frozen_string_literal: true

# This migration comes from decidim_proposals (originally 20180212152542)
class AddWeightOnProposalsVotes < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_proposals_proposal_votes, :weight, :integer
  end
end
