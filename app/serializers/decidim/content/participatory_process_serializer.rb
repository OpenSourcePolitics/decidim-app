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
          reference: resource.try(:reference),
          short_description: normalize_translated_attribute(resource.short_description),
          description: normalize_translated_attribute(resource.description),
          announcement: normalize_translated_attribute(resource.announcement),
          start_date: resource.start_date,
          end_date: resource.end_date,
          hero_image: blob_url(resource.hero_image, resource.organization),
          participatory_process_group: uid(resource.try(:participatory_process_group)),
          participatory_process_type: normalize_translated_attribute(resource.participatory_process_type.try(:title)),
          area: uid(resource.try(:area)),
          scopes_enabled: resource.scopes_enabled,
          scope: uid(resource.try(:scope)),
          private_space: resource.private_space,
          promoted: resource.promoted,
          metadata: {
            hashtag: resource.hashtag,
            developer_group: normalize_translated_attribute(resource.try(:developer_group)),
            local_area: normalize_translated_attribute(resource.try(:local_area)),
            meta_scope: normalize_translated_attribute(resource.try(:meta_scope)),
            target: normalize_translated_attribute(resource.try(:target)),
            participatory_scope: normalize_translated_attribute(resource.try(:participatory_scope)),
            participatory_structure: normalize_translated_attribute(resource.try(:participatory_structure))
          },
          weight: resource.weight,
          created_at: resource.created_at,
          updated_at: resource.updated_at,
          published_at: resource.try(:published_at),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        }
      end
    end
  end
end
