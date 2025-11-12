# frozen_string_literal: true

module Admin
  class ReorderProposalStates < Decidim::Command
    def initialize(component, ids)
      @component = component
      @ids = ids
    end

    def call
      return broadcast(:invalid) if @ids.blank?

      reorder_proposal_states
      broadcast(:ok)
    end

    def collection
      @collection ||= Decidim::Proposals::ProposalState.where(
        id: @ids,
        component: @component
      )
    end

    def reorder_proposal_states
      transaction do
        set_new_weights
      end
    end

    def set_new_weights
      @ids.each do |id|
        current_state = collection.find { |state| state.id == id.to_i }
        next if current_state.blank?

        new_weight = @ids.index(id) + 1
        current_state.update!(weight: new_weight)
      end
    end
  end
end
