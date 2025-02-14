# frozen_string_literal: true

require "active_support/concern"
module PublishProposalExtends
  extend ActiveSupport::Concern

  included do
    def call
      return broadcast(:invalid) unless @proposal.authored_by?(@current_user)

      transaction do
        publish_proposal
        increment_scores
        send_notification
        send_notification_to_participatory_space
        send_publication_notification
      end

      broadcast(:ok, @proposal)
    end

    private

    def send_publication_notification
      Decidim::EventsManager.publish(
        event: "decidim.events.proposals.author_confirmation_proposal_event",
        event_class: Decidim::Proposals::AuthorConfirmationProposalEvent,
        resource: @proposal,
        affected_users: [@proposal.creator_identity],
        extra: { force_email: true },
        force_send: true
      )
    end
  end
end

Decidim::Proposals::PublishProposal.include(PublishProposalExtends)
