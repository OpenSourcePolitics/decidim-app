# app/events/decidim/proposals/proposal_published_event.rb
module Decidim
  module Proposals
    class ProposalPublishedEvent < Decidim::Events::BaseEvent
      include Decidim::Events::NotificationEvent

      def self.model_name
        ActiveModel::Name.new(self, nil, I18n.t('decidim.proposals.notifications.proposal_published.subject'))
      end

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
        Decidim::Proposals::Engine.routes.url_helpers.proposal_path(
          resource,
          component_id: resource.component.id,
          initiative_slug: resource.component.participatory_space.slug
        )
      end
    end
  end
end
