# frozen_string_literal: true

module Decidim
  module Content
    class ProposalVoteSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          proposal: uid(Decidim::Proposals::Proposal.new(id: resource.decidim_proposal_id)),
          # author: uid(identity(resource)), # if there is user groups involved
          author: uid(Decidim::User.new(id: resource.decidim_author_id)),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          weight: resource.try(:weight),
          temporary: resource.try(:temporary)
        }
      end
    end
  end
end
