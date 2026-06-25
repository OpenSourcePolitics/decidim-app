# frozen_string_literal: true

module Decidim
  module Content
    class ProposalNoteSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          proposal: uid(Decidim::Proposals::Proposal.new(id: resource.decidim_proposal_id)),
          # author: uid(identity(resource)), # if there is user groups involved
          author: uid(Decidim::User.new(id: resource.decidim_author_id)),
          body: normalize_translated_attribute(resource.try(:body)),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at)
        }
      end
    end
  end
end
