# frozen_string_literal: true

module Decidim
  module Content
    class AssembliesTypeSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          title: normalize_translated_attribute(resource.title),
          created_at: resource.created_at,
          updated_at: resource.updated_at
        }
      end
    end
  end
end
