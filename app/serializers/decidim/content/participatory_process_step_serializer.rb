# frozen_string_literal: true

module Decidim
  module Content
    class ParticipatoryProcessStepSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          title: normalize_translated_attribute(resource.title),
          description: normalize_translated_attribute(resource.description),
          start_date: resource.try(:start_date),
          end_date: resource.try(:end_date),
          active: resource.try(:active),
          cta_path: resource.try(:cta_path),
          cta_text: normalize_translated_attribute(resource.cta_text),
          position: resource.try(:position)
        }
      end
    end
  end
end
