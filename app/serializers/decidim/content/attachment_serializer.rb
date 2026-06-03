# frozen_string_literal: true

module Decidim
  module Content
    class AttachmentSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          title: normalize_translated_attribute(resource.title),
          description: normalize_translated_attribute(resource.description),
          weight: resource.try(:weight),
          # file: Decidim::AttachmentPresenter.new(resource).attachment_file_url
          file: blob_url(resource.file, resource.organization)
        }
      end
    end
  end
end
