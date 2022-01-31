# frozen_string_literal: true

class FixI18nCommentBody < ActiveRecord::Migration[5.2]
  def change
    PaperTrail.request(enabled: false) do
      Decidim::Comments::Comment.find_each do |comment|
        fix_content(comment, :body)

        comment.save! if comment.has_changes_to_save?
      end
    end
  end

  def fix_content(resource, attribute)
    if resource.send(attribute).is_a?(Hash)
      resource.send(attribute).keys.each do |k|
        if resource.send(attribute)[k].is_a?(Hash) && resource.send(attribute)[k].has_key?(k) && resource.send(attribute)[k][k].is_a?(String)
          resource.send(attribute)[k] = resource.send(attribute)[k][k]
        end
      end
    end
  end
end
