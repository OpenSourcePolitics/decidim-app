# frozen_string_literal: true

require "active_support/concern"

module UpdateContentBlockExtends
  extend ActiveSupport::Concern

  included do
    private

    def update_content_block_images
      params = form.respond_to?(:image_params) ? form.image_params : (form.attributes["images"] || {})
      content_block.manifest.images.each do |image_config|
        image_name = image_config[:name]
        val = params[image_name] || params[image_name.to_s]
        if val
          content_block.images_container.send("#{image_name}=", val)
        elsif params[:"remove_#{image_name}"] == "1" || params["remove_#{image_name}"] == "1"
          content_block.images_container.send("#{image_name}=", nil)
        end
      end
    end
  end
end

Decidim::Admin::ContentBlocks::UpdateContentBlock.include(UpdateContentBlockExtends)
