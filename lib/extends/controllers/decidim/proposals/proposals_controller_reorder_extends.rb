# frozen_string_literal: true

module Decidim
  module Proposals
    module ProposalsControllerReorderTiebreaker
      private

      def reorder(proposals)
        super.order(id: :desc)
      end
    end
  end
end

Decidim::Proposals::ProposalsController.prepend(
  Decidim::Proposals::ProposalsControllerReorderTiebreaker
)
