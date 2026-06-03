# frozen_string_literal: true

module Decidim
  module Content
    class CategorySerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          parent: parent_uid,
          name: normalize_translated_attribute(resource.name),
          description: normalize_translated_attribute(resource.description),
          weight: resource.try(:weight),
          text_color: resource.try(:text_color),
          background_color: resource.try(:background_color)
        }
      end

      private

      def parent_uid
        uid(Decidim::Category.new(id: resource.parent_id)) if resource.parent_id.present?
      end
    end
  end
end
