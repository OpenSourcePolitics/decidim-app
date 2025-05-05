# frozen_string_literal: true

require "active_support/concern"

module CommentMetadataCellExtends
  extend ActiveSupport::Concern

  included do
    def items
      [author_item, commentable_item, comments_count_item].compact
    end
  end
end

Decidim::Comments::CommentMetadataCell.include(CommentMetadataCellExtends)
