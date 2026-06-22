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
          settings: convert_settings_to_uid(resource[:settings]),
          weight: resource.try(:weight),
          permissions: resource.try(:permissions),
          published_at: resource.try(:published_at),
          previously_published: resource.try(:previously_published?),
          specific_data: resource.manifest.specific_data_serializer_class&.new(resource)&.run,
          url: Decidim::EngineRouter.main_proxy(resource)&.root_url
        }
      end

      def convert_settings_to_uid(settings)
        return unless settings

        settings["steps"].transform_keys! { |key| uid(Decidim::ParticipatoryProcessStep.new(id: key.to_i)) } if settings["steps"]
        settings["global"]["scope_id"] = uid(Decidim::Scope.new(id: settings["global"]["scope_id"].to_i)) if settings.dig("global", "scope_id")
      end
    end
  end
end
