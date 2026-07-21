# frozen_string_literal: true

module Decidim
  module Content
    class SortitionSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          author: uid(identity(resource)),
          reference: resource.try(:reference),
          title: normalize_translated_attribute(resource.try(:title)),
          additional_info: normalize_translated_attribute(resource.try(:additional_info)),
          witnesses: normalize_translated_attribute(resource.try(:witnesses)),
          proposals_component: uid(Decidim::Component.new(id: resource.try(:decidim_proposals_component_id))),
          candidate_proposals: resource.try(:candidate_proposals)&.map { |id| uid(Decidim::Proposals::Proposal.new(id:)) },
          selected_proposals: resource.try(:selected_proposals)&.map { |id| uid(Decidim::Proposals::Proposal.new(id:)) },
          target_items: resource.try(:target_items),
          dice: resource.try(:dice),
          request_timestamp: resource.try(:request_timestamp),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          comments_count: resource.try(:comments_count),
          cancelled_on: resource.try(:cancelled_on),
          cancelled_reason: resource.try(:cancelled_reason),
          cancelled_by: uid(Decidim::User.new(id: resource.try(:cancelled_by_user_id))),
          component: uid(resource.try(:component)),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        }
      end
    end
  end
end
