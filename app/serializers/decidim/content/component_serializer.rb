# frozen_string_literal: true

module Decidim
  module Content
    class ComponentSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          manifest_name: resource.manifest_name,
          name: normalize_translated_attribute(resource.name),
          settings: resource[:settings],
          weight: resource.try(:weight),
          permissions: resource.try(:permissions),
          published_at: resource.try(:published_at)
        }.merge(specific_data: resource.manifest.specific_data_serializer_class&.new(resource)&.run)
      end
    end
  end
end
