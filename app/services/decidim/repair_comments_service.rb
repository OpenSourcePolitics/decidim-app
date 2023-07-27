# frozen_string_literal: true

module Decidim
  class RepairCommentsService
    include Decidim::TranslatableAttributes

    def self.run
      new.execute
    end

    def execute
      return [] if ok?

      update_comments!
    end

    def ok?
      invalid_comments.empty?
    end

    def invalid_comments
      return @invalid_comments if @invalid_comments

      invalid_comments = []
      Decidim::Comments::Comment.find_each do |comment|
        next if translated_attribute(comment.body).is_a?(String)

        comment.body.delete("machine_translations")
        invalid_comments << [comment, comment.body.values.first]
      end
      @invalid_comments = invalid_comments
    end

    private

    # Update each users with new nickname
    # Returns Array of updated User ID
    def update_comments!
      invalid_comments.map do |comment, new_body|
        comment.body = new_body

        comment.id if comment.save!(validate: false) # Validation is skipped to allow updating comments from root that don't accepts new comments
      end.compact
    end
  end
end
