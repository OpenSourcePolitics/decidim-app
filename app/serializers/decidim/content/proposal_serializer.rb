# frozen_string_literal: true

module Decidim
  module Content
    # see : Decidim::Proposals::ProposalSerializer
    class ProposalSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          authors: coauthors(resource).map { |author| uid(author) },
          category: uid(resource.try(:category)),
          scope: uid(resource.try(:scope)),
          title: normalize_translated_attribute(resource.try(:title)),
          body: normalize_translated_attribute(resource.try(:body)),
          address: resource.try(:address),
          latitude: resource.try(:latitude),
          longitude: resource.try(:longitude),
          state: uid(resource.try(:proposal_state)),
          state_token: resource.try(:internal_state),
          reference: resource.try(:reference),
          answer: normalize_translated_attribute(resource.try(:answer)),
          answered_at: resource.try(:answered_at),
          votes_count: resource.try(:proposal_votes_count),
          endorsements_count: resource.try(:endorsements).try(:size),
          comments_count: resource.try(:comments_count),
          attachments_count: resource.try(:attachments).try(:size),
          followers_count: resource.try(:follows).try(:size),
          published_at: resource.try(:published_at),
          related_proposals: resource.linked_resources(:proposals, "copied_from_component").map { |proposal| uid(proposal) },
          related_meetings: resource.linked_resources(:meetings, "proposals_from_meeting").map { |meeting| uid(meeting) },
          is_amend: resource.try(:emendation?),
          original_proposal: uid(resource.try(:amendable)),
          withdrawn: resource.try(:withdrawn?),
          withdrawn_at: resource.try(:withdrawn_at),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        } # TODO : add custom fields (public & private)
      end
    end
  end
end
