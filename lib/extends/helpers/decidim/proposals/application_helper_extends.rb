# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Proposals
    module ApplicationHelperExtends
      extend ActiveSupport::Concern

      included do
        def filter_proposals_state_values
          Decidim::CheckBoxesTreeHelper::TreeNode.new(
            Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.proposals.application_helper.filter_state_values.all")),
            [
              Decidim::CheckBoxesTreeHelper::TreePoint.new("state_not_published", t("decidim.proposals.application_helper.filter_state_values.not_answered"))
            ] +
            Decidim::Proposals::ProposalState
              .where(component: current_component)
              .where.not(token: "not_answered")
              .order(:weight)
              .map do |state|
              Decidim::CheckBoxesTreeHelper::TreePoint.new(state.token, translated_attribute(state.title))
            end
          )
        end
      end
    end
  end
end

Decidim::Proposals::ApplicationHelper.include(Decidim::Proposals::ApplicationHelperExtends)
