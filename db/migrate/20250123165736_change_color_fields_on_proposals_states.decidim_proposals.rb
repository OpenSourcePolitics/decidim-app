# frozen_string_literal: true

# This migration comes from decidim_proposals (originally 20240209092404)
class ChangeColorFieldsOnProposalsStates < ActiveRecord::Migration[6.1]
  class ProposalState < ApplicationRecord
    self.table_name = :decidim_proposals_proposal_states

    def self.colors
      {
        gray: {
          background: "#F6F8FA",
          foreground: "#4B5058"
        },
        green: {
          background: "#E3FCE9",
          foreground: "#15602C"
        },
        orange: {
          background: "#FFF1E5",
          foreground: "#BC4C00"
        },
        red: {
          background: "#FFEBE9",
          foreground: "#D1242F"
        }
      }
    end
  end

  def up
    add_column :decidim_proposals_proposal_states, :bg_color, :string, default: "#F6F8FA", null: false, if_not_exists: true
    add_column :decidim_proposals_proposal_states, :text_color, :string, default: "#4B5058", null: false, if_not_exists: true

    colors = ProposalState.colors

    # rubocop:disable Rails/SkipsModelValidations
    ProposalState.where(token: :accepted).update_all(
      bg_color: colors[:green][:background], text_color: colors[:green][:foreground]
    )
    ProposalState.where(token: :evaluating).update_all(
      bg_color: colors[:orange][:background], text_color: colors[:orange][:foreground]
    )
    ProposalState.where(token: :rejected).update_all(
      bg_color: colors[:red][:background], text_color: colors[:red][:foreground]
    )
    # rubocop:enable Rails/SkipsModelValidations
  rescue ActiveModel::UnknownAttributeError
    # Skip migration
  end

  def down; end
end
