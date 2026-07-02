# frozen_string_literal: true

module Decidim
  module Content
    class AssemblySerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          parent: resource.try(:parent_id).present? ? uid(Decidim::Assembly.new(id: resource.parent_id)) : nil,
          assembly_path: resource.parents_path.split(".").map { |parent| uid(Decidim::Assembly.new(id: parent.to_i)) },
          children_count: resource.children_count,
          assembly_type: resource.try(:decidim_assemblies_type_id).present? ? uid(Decidim::AssembliesType.new(id: resource.decidim_assemblies_type_id)) : nil,
          slug: resource.slug,
          reference: resource.try(:reference),
          title: normalize_translated_attribute(resource.title),
          subtitle: normalize_translated_attribute(resource.subtitle),
          short_description: normalize_translated_attribute(resource.short_description),
          description: normalize_translated_attribute(resource.description),
          purpose_of_action: normalize_translated_attribute(resource.try(:purpose_of_action)),
          composition: normalize_translated_attribute(resource.try(:composition)),
          internal_organisation: normalize_translated_attribute(resource.try(:internal_organisation)),
          announcement: normalize_translated_attribute(resource.try(:announcement)),
          creation_date: resource.try(:creation_date),
          included_at: resource.try(:included_at),
          duration: resource.try(:duration),
          closing_date: resource.try(:closing_date),
          closing_date_reason: normalize_translated_attribute(resource.try(:closing_date_reason)),
          created_by: resource.try(:created_by),
          created_by_other: normalize_translated_attribute(resource.try(:created_by_other)),
          hero_image: blob_url(resource.hero_image, resource.organization),
          banner_image: blob_url(resource.banner_image, resource.organization),
          area: uid(resource.try(:area)),
          scopes_enabled: resource.scopes_enabled,
          scope: uid(resource.try(:scope)),
          private_space: resource.private_space,
          is_transparent: resource.try(:is_transparent),
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
          social_media: {
            twitter_handler: resource.try(:twitter_handler),
            instagram_handler: resource.try(:instagram_handler),
            facebook_handler: resource.try(:facebook_handler),
            youtube_handler: resource.try(:youtube_handler),
            github_handler: resource.try(:github_handler)
          },
          special_features: normalize_translated_attribute(resource.try(:special_features)),
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
