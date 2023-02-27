# frozen_string_literal: true

module Decidim
  module ContentBlocks
    module HeroCellExtends
      def cache_hash
        hash = []
        hash << "decidim/content_blocks/hero"
        hash << Digest::MD5.hexdigest(model.attributes.to_s)
        hash << current_organization.cache_key_with_version
        hash << I18n.locale.to_s
        hash << background_image

        hash.join(Decidim.cache_key_separator)
      end
    end
  end
end

Decidim::ContentBlocks::HeroCell.class_eval do
  prepend Decidim::ContentBlocks::HeroCellExtends
end
