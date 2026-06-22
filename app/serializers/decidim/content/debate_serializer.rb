# frozen_string_literal: true

module Decidim
  module Content
    class DebateSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          author: uid(identity(resource)),
          category: uid(resource.try(:category)),
          title: normalize_translated_attribute(resource.try(:title)),
          description: normalize_translated_attribute(resource.try(:description)),
          instructions: normalize_translated_attribute(resource.try(:instructions)),
          information_updates: normalize_translated_attribute(resource.try(:information_updates)),
          conclusions: normalize_translated_attribute(resource.try(:conclusions)),
          start_time: resource.try(:start_time),
          end_time: resource.try(:end_time),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          closed_at: resource.try(:closed_at),
          reference: resource.try(:reference),
          comments_enabled: resource.try(:comments_enabled),
          comments_count: resource.try(:comments_count),
          endorsements_count: resource.try(:endorsements).try(:size),
          followers_count: resource.try(:follows).try(:size),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        }
      end
    end
  end
end
