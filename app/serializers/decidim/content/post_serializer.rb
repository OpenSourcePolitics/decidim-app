# frozen_string_literal: true

module Decidim
  module Content
    class PostSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          author: uid(identity(resource)),
          title: normalize_translated_attribute(resource.try(:title)),
          body: normalize_translated_attribute(resource.try(:body)),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          published_at: resource.try(:published_at),
          endorsements_count: resource.try(:endorsements_count),
          follows_count: resource.try(:follows_count),
          comments_count: resource.try(:comments_count),
          component: uid(resource.try(:component)),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        }
      end
    end
  end
end
