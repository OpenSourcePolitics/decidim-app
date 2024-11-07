# app/events/decidim/proposals/proposal_published_event.rb
module Decidim
  module Proposals
    class ProposalPublishedEvent < Decidim::Events::SimpleEvent
      def notification_title
        I18n.t("decidim.proposals.notifications.proposal_published.title", proposal_title: resource_title)
      end

      def notification_body
        I18n.t("decidim.proposals.notifications.proposal_published.body", proposal_link: resource_path)
      end

      private

      def resource_title
        translated_attribute(resource.title)
      end

      def resource_path
        ""
      end
    end
  end
end
