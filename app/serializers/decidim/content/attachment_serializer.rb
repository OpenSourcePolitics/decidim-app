# frozen_string_literal: true

module Decidim
  module Content
    class AttachmentSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          title: normalize_translated_attribute(resource.title),
          description: normalize_translated_attribute(resource.description),
          weight: resource.try(:weight),
          # file: Decidim::AttachmentPresenter.new(resource).attachment_file_url
          file: blob_url(resource.file, resource.organization),
          attached_to: polymorphic_uid(resource, :attached_to),
          collection: uid(Decidim::AttachmentCollection.new(id: resource.try(:attachment_collection_id)))
        }
      end
    end
  end
end
