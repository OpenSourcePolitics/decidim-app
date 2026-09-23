# frozen_string_literal: true

module Decidim
  module Content
    class CommentVoteSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          comment: uid(Decidim::Comments::Comment.new(id: resource.try(:decidim_comment_id))),
          author: uid(identity(resource)),
          value: comment_vote_value,
          weight: resource.try(:weight),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at)
        }
      end

      def comment_vote_value
        case resource.try(:weight)
        when 1
          "up"
        when -1
          "down"
        end
      end
    end
  end
end
