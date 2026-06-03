# frozen_string_literal: true

module Decidim
  module Content
    class ParticipatorySpaceUserSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(Decidim::User.new(id: resource[:decidim_user_id])),
          role: resource[:role]
        }
      end
    end
  end
end
