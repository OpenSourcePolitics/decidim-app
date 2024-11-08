# frozen_string_literal: true

module Decidim
  module Proposals
    class AuthorConfirmationProposalEvent < Decidim::Events::SimpleEvent
      def resource_title
        translated_attribute(resource.title)
      end
    end
  end
end
