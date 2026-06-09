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

        def normalize_translated_attribute(attribute)
          # NOTES : if returning nil creates issues then return empty_translatable
          return nil if attribute.blank?
          return attribute unless attribute.is_a?(Hash) && attribute["machine_translations"].present?

          attribute.merge(attribute.delete("machine_translations"))
        end
      end
    end
  end
end
