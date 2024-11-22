# frozen_string_literal: true

module Decidim
  module Proposals
    # A command with all the business logic when a user publishes a draft proposal.
    class PublishProposal < Decidim::Command
      include Decidim::AnonymousProposals::AnonymousBehaviorCommandsConcern

      # Public: Initializes the command.
      #
      # proposal     - The proposal to publish.
      # current_user - The current user.
      # override: decidim-module-anonymous_proposals/app/commands/decidim/anonymous_proposals/publish_proposal_command_overrides.rb
      def initialize(proposal, current_user)
        @proposal = proposal
        @is_anonymous = allow_anonymous_proposals? && (current_user.blank? || proposal.authored_by?(anonymous_group))
        set_current_user(current_user)
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the proposal is published.
      # - :invalid if the proposal's author is not the current user.
      #
      # Returns nothing.
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

      # This will be the PaperTrail version that is
      # shown in the version control feature (1 of 1)
      #
      # For an attribute to appear in the new version it has to be reset
      # and reassigned, as PaperTrail only keeps track of object CHANGES.
      def publish_proposal
        title = reset(:title)
        body = reset(:body)

        Decidim.traceability.perform_action!(
          "publish",
          @proposal,
          @current_user,
          visibility: "public-only"
        ) do
          @proposal.update title: title, body: body, published_at: Time.current
        end
      end

      # Reset the attribute to an empty string and return the old value
      def reset(attribute)
        attribute_value = @proposal[attribute]
        PaperTrail.request(enabled: false) do
          # rubocop:disable Rails/SkipsModelValidations
          @proposal.update_attribute attribute, ""
          # rubocop:enable Rails/SkipsModelValidations
        end
        attribute_value
      end

      def send_notification
        return if @proposal.coauthorships.empty?

        Decidim::EventsManager.publish(
          event: "decidim.events.proposals.proposal_published",
          event_class: Decidim::Proposals::PublishProposalEvent,
          resource: @proposal,
          followers: coauthors_followers
        )
      end

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

      def send_notification_to_participatory_space
        Decidim::EventsManager.publish(
          event: "decidim.events.proposals.proposal_published",
          event_class: Decidim::Proposals::PublishProposalEvent,
          resource: @proposal,
          followers: @proposal.participatory_space.followers - coauthors_followers,
          extra: {
            participatory_space: true
          }
        )
      end

      def coauthors_followers
        @coauthors_followers ||= @proposal.authors.flat_map(&:followers)
      end

      def increment_scores
        @proposal.coauthorships.find_each do |coauthorship|
          if coauthorship.user_group
            Decidim::Gamification.increment_score(coauthorship.user_group, :proposals)
          else
            Decidim::Gamification.increment_score(coauthorship.author, :proposals)
          end
        end
      end

      # override: decidim-module-anonymous_proposals/app/commands/decidim/anonymous_proposals/publish_proposal_command_overrides.rb
      def component
        @component ||= @proposal.component
      end
    end
  end
end
