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
          # Aparently, this is only used for root_commentable, but Comments can't be root_commentable, so this is always 0.
          # comments_count: resource.comments_count,
          commentable: polymorphic_uid(resource, :decidim_commentable),
          root_commentable: polymorphic_uid(resource, :decidim_root_commentable),
          created_at: resource.created_at,
          updated_at: resource.updated_at,
          url: single_comment_url
        }
      end

      def root_commentable
        if defined?(Decidim::Budgets) && resource.root_commentable.is_a?(Decidim::Budgets::Project)
          [resource.root_commentable.budget, resource.root_commentable]
        else
          resource.root_commentable
        end
      end

      def single_comment_url
        "#{Decidim::ResourceLocatorPresenter.new(root_commentable).url(commentId: resource.id)}#comment_#{resource.id}"
      end
    end
  end
end
