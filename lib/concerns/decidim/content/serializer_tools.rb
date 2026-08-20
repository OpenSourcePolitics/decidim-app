# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module SerializerTools
      extend ActiveSupport::Concern
      included do
        # include Decidim::ResourceHelper
        include Decidim::TranslationsHelper
        include Decidim::Content::UrlTools
        include Decidim::Content::UidTools
        include Decidim::Content::AuthorableTools
        include Decidim::Content::QuestionnaireTools
        include Decidim::Content::DecidimAwesomeTools

        def normalize_translated_attribute(attribute)
          # NOTES : if returning nil creates issues then return empty_translatable
          return nil if attribute.blank?
          return attribute unless attribute.is_a?(Hash) && attribute["machine_translations"].present?

          attribute.merge(attribute.delete("machine_translations"))
        end

        def convert_newlines_to_html(text)
          return text unless text.is_a?(String)

          text.gsub(/\r\n|\r|\n/, "<br/>")
        end
      end
    end
  end
end
