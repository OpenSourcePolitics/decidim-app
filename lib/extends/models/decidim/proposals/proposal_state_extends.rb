# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Proposals
    module ProposalStateExtends
      extend ActiveSupport::Concern

      included do
        before_validation :set_default_weight, on: :create

        scope :ordered_by_weight, -> { order(:weight) }

        private

        def set_default_weight
          return if weight.present?

          max_weight = self.class.where(component:).maximum(:weight) || 0
          self.weight = max_weight + 1
        end
      end
    end
  end
end

Decidim::Proposals::ProposalState.include(Decidim::Proposals::ProposalStateExtends)
