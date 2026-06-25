# frozen_string_literal: true

module Decidim
  module Content
    class EndorsementSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          author: uid(identity(resource)),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          endorsement_for: polymorphic_uid(resource, :resource)
        }
      end
    end
  end
end
