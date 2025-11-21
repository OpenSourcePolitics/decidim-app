# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Proposals
    module Admin
      module ProposalStatesControllerExtends
        extend ActiveSupport::Concern

        included do
          def update
            return update_proposal_states if params[:id] == "refresh_proposal_states"

            enforce_permission_to(:update, :proposal_state, proposal_state:)
            @form = form(ProposalStateForm).from_params(params)

            UpdateProposalState.call(@form, proposal_state) do
              on(:ok) do
                flash[:notice] = I18n.t("proposal_states.update.success", scope: "decidim.proposals.admin")
                redirect_to proposal_states_path
              end

              on(:invalid) do
                flash.now[:alert] = I18n.t("proposal_states.update.error", scope: "decidim.proposals.admin")
                render action: :edit
              end
            end
          end

          private

          def proposal_states
            @proposal_states ||= paginate(ProposalState.where(component: current_component).order(:weight))
          end

          def update_proposal_states
            enforce_permission_to :update, :proposal_state

            ::Admin::ReorderProposalStates.call(current_component, params[:manifests]) do
              on(:ok) do
                head :ok
              end
              on(:invalid) do
                head :unprocessable_entity
              end
            end
          end
        end
      end
    end
  end
end

Decidim::Proposals::Admin::ProposalStatesController.include(Decidim::Proposals::Admin::ProposalStatesControllerExtends)
