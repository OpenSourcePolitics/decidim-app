# frozen_string_literal: true
# This migration comes from decidim_custom_proposal_states (originally 20231102234909)

class CreateDefaultProposalStates < ActiveRecord::Migration[6.0]
  class Proposal < ApplicationRecord
    belongs_to :proposal_state,
               class_name: "Decidim::CustomProposalStates::ProposalState",
               foreign_key: "decidim_proposals_proposal_state_id",
               inverse_of: :proposals,
               optional: true

    self.table_name = :decidim_proposals_proposals
  end

  def up
    states = {
      "0" => :not_answered,
      "10" => :evaluating,
      "20" => :accepted,
      "-10" => :rejected,
      "-20" => :withdrawn
    }

    Proposal.where(state: "").update_all(state: "not_answered")
    Proposal.where(state: nil).update_all(state: "not_answered")

    Decidim::Component.where(manifest_name: "proposals").find_each do |component|
      admin_user = component.organization.admins.first
      default_states = Decidim::CustomProposalStates.create_default_states!(component, admin_user).with_indifferent_access
      Proposal.where(decidim_component_id: component.id).find_each do |proposal|
        proposal.proposal_state = default_states.dig(proposal.state.to_s, :object)
        proposal.save!
      end
    end
    change_column_null :decidim_proposals_proposals, :decidim_proposals_proposal_state_id, false
  end

  def down; end
end
