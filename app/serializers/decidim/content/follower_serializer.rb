# frozen_string_literal: true

module Decidim
  module Content
    class FollowerSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          user: uid(Decidim::User.new(id: resource.decidim_user_id)),
          followable: polymorphic_uid(resource, :decidim_followable),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at)
        }
      end
    end
  end
end
