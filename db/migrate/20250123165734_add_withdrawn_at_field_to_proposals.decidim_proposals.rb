# frozen_string_literal: true

# This migration comes from decidim_proposals (originally 20240110203500)
class AddWithdrawnAtFieldToProposals < ActiveRecord::Migration[6.1]
  class CustomProposal < Decidim::Proposals::ApplicationRecord
    self.table_name = "decidim_proposals_proposals"
    STATES = { not_answered: 0, evaluating: 10, accepted: 20, rejected: -10, withdrawn: -20 }.freeze
    enum state: STATES, _default: "not_answered"
  end

  def up
    add_column :decidim_proposals_proposals, :withdrawn_at, :datetime

    CustomProposal.withdrawn.find_each do |proposal|
      proposal.withdrawn_at = proposal.updated_at
      proposal.state = :not_answered
      proposal.save!
    end
  end

  def down
    CustomProposal.where.not(withdrawn_at: nil).find_each do |proposal|
      proposal.state = :withdrawn
      proposal.save!
    end

    remove_column :decidim_proposals_proposals, :withdrawn_at
  end
end
