# frozen_string_literal: true

module Decidim
  module Content
    class AccountabilityStatusSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          key: resource.try(:key),
          name: normalize_translated_attribute(resource.try(:name)),
          description: normalize_translated_attribute(resource.try(:description)),
          progress: resource.try(:progress),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          component: uid(resource.try(:component))
        }
      end
    end
  end
end
