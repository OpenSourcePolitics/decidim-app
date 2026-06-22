# frozen_string_literal: true

module Decidim
  module Content
    class ParticipatoryProcessGroupSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      delegate :organization, to: :resource

      def serialize
        {
          uid: uid(resource),
          title: normalize_translated_attribute(resource.title),
          description: normalize_translated_attribute(resource.description),
          hero_image: blob_url(resource.hero_image, resource.organization),
          promoted: resource.promoted,
          metadata: {
            hashtag: resource.hashtag,
            group_url: resource.group_url,
            developer_group: resource.developer_group,
            local_area: resource.local_area,
            meta_scope: resource.meta_scope,
            target: resource.target,
            participatory_scope: resource.participatory_scope,
            participatory_structure: resource.participatory_structure
          },
          created_at: resource.created_at,
          updated_at: resource.updated_at,
          url: switch_url_port(Decidim::ParticipatoryProcesses::Engine.routes.url_helpers.participatory_process_group_url(resource, host: resource.organization.host))
        }
      end
    end
  end
end
