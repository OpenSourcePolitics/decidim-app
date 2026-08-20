# frozen_string_literal: true

module Decidim
  module Content
    class ProposalStateSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          title: normalize_translated_attribute(resource.try(:title)),
          description: normalize_translated_attribute(resource.try(:description)),
          announcement_title: normalize_translated_attribute(resource.try(:announcement_title)),
          token: resource.try(:token),
          system: resource.try(:system),
          default: resource.try(:default),
          proposals_count: resource.try(:proposals_count),
          answerable: resource.try(:answerable),
          notifiable: resource.try(:notifiable),
          gamified: resource.try(:gamified),
          # include_in_stats: resource.try(:include_in_stats),
          css_class: resource.try(:css_class),
          bg_color: resource.try(:bg_color),
          text_color: resource.try(:text_color),
          weight: resource.try(:weight),
          component: uid(resource.try(:component))
        }
      end
    end
  end
end
