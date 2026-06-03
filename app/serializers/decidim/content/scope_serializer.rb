# frozen_string_literal: true

module Decidim
  module Content
    class ScopeSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          parent: parent_uid,
          code: resource.code,
          name: normalize_translated_attribute(resource.name),
          scope_type: normalize_translated_attribute(resource.scope_type&.name),
          # part_of: resource.part_of.map { |id| uid(Decidim::Scope.new(id:)) },
          # geojson: resource.geojson,
          weight: resource.weight,
          created_at: resource.created_at,
          updated_at: resource.updated_at
        }
      end

      private

      def parent_uid
        uid(Decidim::Scope.new(id: resource.parent_id)) if resource.parent_id.present?
      end
    end
  end
end
