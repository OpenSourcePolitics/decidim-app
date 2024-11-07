# app/events/decidim/proposals/proposal_published_event.rb
module Decidim
  module Proposals
    class ProposalPublishedEvent < Decidim::Events::SimpleEvent
      def resource_title
        translated_attribute(resource.title)
      end
    end
  end
end
