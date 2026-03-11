# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Proposals
    module ProposalsControllerExtends
      extend ActiveSupport::Concern

      included do
        def index
          if component_settings.participatory_texts_enabled?
            @proposals = Decidim::Proposals::Proposal
                         .where(component: current_component)
                         .published
                         .not_hidden
                         .only_amendables
                         .includes(:category, :scope, :attachments, :coauthorships)
                         .order(position: :asc)
            render "decidim/proposals/proposals/participatory_texts/participatory_text"
          else
            @proposals = search.result
            @proposals = reorder(@proposals)
            ids = @proposals.ids
            @proposals = Decidim::Proposals::Proposal.where(id: ids)
                                                     .order(Arel.sql("position(decidim_proposals_proposals.id::text in '#{ids.join(",")}')"))
                                                     .page(params[:page])
                                                     .per(per_page)
            @proposals = @proposals.includes(:component, :coauthorships, :attachments)

            @voted_proposals = if current_user
                                 ProposalVote.where(
                                   author: current_user,
                                   proposal: @proposals.pluck(:id)
                                 ).pluck(:decidim_proposal_id)
                               else
                                 []
                               end
          end
        end

        private

        def default_filter_params
          {
            activity: "all",
            related_to: "",
            search_text_cont: "",
            type: "all",
            with_any_category: nil,
            with_any_origin: nil,
            with_any_scope: nil,
            with_any_state: default_states
          }
        end
      end
    end
  end
end

Decidim::Proposals::ProposalsController.include(Decidim::Proposals::ProposalsControllerExtends)
