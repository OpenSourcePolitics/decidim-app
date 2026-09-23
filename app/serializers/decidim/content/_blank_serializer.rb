# frozen_string_literal: true

module Decidim
  module Content
    class BlankSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource)
        }
      end
    end
  end
end
