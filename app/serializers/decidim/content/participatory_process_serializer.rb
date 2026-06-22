# frozen_string_literal: true

module Decidim
  module Content
    class ParticipatoryProcessSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          title: normalize_translated_attribute(resource.title),
          subtitle: normalize_translated_attribute(resource.subtitle),
          slug: resource.slug,
          short_description: normalize_translated_attribute(resource.short_description),
          description: normalize_translated_attribute(resource.description),
          announcement: normalize_translated_attribute(resource.announcement),
          start_date: resource.start_date,
          end_date: resource.end_date,
          hero_image: blob_url(resource.hero_image, resource.organization),
          participatory_process_group: uid(resource.try(:participatory_process_group)),
          participatory_process_type: normalize_translated_attribute(resource.participatory_process_type.try(:title)),
          area: uid(resource.try(:area)),
          scope: uid(resource.try(:scope)),
          private_space: resource.private_space,
          promoted: resource.promoted,
          scopes_enabled: resource.scopes_enabled,
          metadata: {
            hashtag: resource.hashtag,
            developer_group: resource.developer_group,
            local_area: resource.local_area,
            meta_scope: resource.meta_scope,
            target: resource.target,
            participatory_scope: resource.participatory_scope,
            participatory_structure: resource.participatory_structure
          },
          created_at: resource.created_at,
          updated_at: resource.updated_at,
          published_at: resource.try(:published_at),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        }
      end
    end
  end
end
