# frozen_string_literal: true

require "active_support/concern"

module EditorImageFormExtends
  extend ActiveSupport::Concern

  included do
    validate :no_special_character_in_file_name

    # do not allow special characters like accents, spaces..except dash in image filename
    # added to avoid broken images in proposals custom fields rich text editor
    def no_special_character_in_file_name
      if /\W/=~ file.original_filename.split(".").first
        errors.add :file, :invalid
      end
    end
  end
end

Decidim::EditorImageForm.include(EditorImageFormExtends)
