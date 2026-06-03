# frozen_string_literal: true

module Decidim
  module Content
    class AreaSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          # decidim_organization_id: resource.decidim_organization_id,
          name: normalize_translated_attribute(resource.name),
          area_type: normalize_translated_attribute(resource.area_type&.name),
          created_at: resource.created_at,
          updated_at: resource.updated_at
        }
      end
    end
  end
end
