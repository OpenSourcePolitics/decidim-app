# frozen_string_literal: true

require "active_support/concern"

module ProposalMetadataCellExtends
  extend ActiveSupport::Concern

  included do
    # state_item is overridden to fix when model.proposal_state is nil (ex: Proposal not_answered state)
    def state_item
      return if state.blank? || @options.fetch(:skip_state, false)

      if model.withdrawn?
        { text: content_tag(:span, humanize_proposal_state(:withdrawn), class: "label alert") }
      elsif model.emendation?
        { text: content_tag(:span, humanize_proposal_state(state), class: "label #{state_class}") }
      else
        { text: content_tag(:span, translated_attribute(model.proposal_state&.title), class: "label", style: model.proposal_state&.css_style) }
      end
    end
  end
end

Decidim::Proposals::ProposalMetadataCell.include(ProposalMetadataCellExtends)
