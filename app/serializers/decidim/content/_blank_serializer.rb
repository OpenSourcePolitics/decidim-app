# frozen_string_literal: true

module Decidim
  module Content
    class BlankSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource)
        }
      end
    end
  end
end
