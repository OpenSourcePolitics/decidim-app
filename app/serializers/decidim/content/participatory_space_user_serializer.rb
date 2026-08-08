# frozen_string_literal: true

module Decidim
  module Content
    class ParticipatorySpaceUserSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(Decidim::User.new(id: resource[:decidim_user_id])),
          role: resource[:role]
        }
      end
    end
  end
end
