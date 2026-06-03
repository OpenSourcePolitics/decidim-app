# frozen_string_literal: true

module Decidim
  module Content
    class AttachmentCollectionSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          name: normalize_translated_attribute(resource.name),
          weight: resource.try(:weight),
          description: normalize_translated_attribute(resource.description)
        }
      end
    end
  end
end
