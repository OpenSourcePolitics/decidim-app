# frozen_string_literal: true

class FixI18nAttachmentTitle < ActiveRecord::Migration[5.2]
  def change
    PaperTrail.request(enabled: false) do
      Decidim::Attachment.find_each do |attachment|
        fix_content(attachment, :title)
        fix_content(attachment, :description)

        attachment.save!(validate: false) if attachment.has_changes_to_save?
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
