# frozen_string_literal: true

module Decidim
  module Content
    class CommentSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          body: normalize_translated_attribute(resource.body),
          locale: resource.body.keys.first,
          author: uid(identity(resource)),
          alignment: resource.alignment,
          up_votes_count: resource.up_votes&.count,
          down_votes_count: resource.down_votes&.count,
          depth: resource.depth,
          comments_count: resource.comments_count,
          commentable_id: resource.decidim_commentable_id,
          commentable_type: resource.decidim_commentable_type,
          root_commentable_id: resource.decidim_commentable_id,
          root_commentable_type: resource.decidim_commentable_type,
          created_at: resource.created_at,
          updated_at: resource.updated_at
        }
      end
    end
  end
end
