# frozen_string_literal: true

module ContentBlockAttachmentExtends
  def uploader
    return if content_block.blank?

    config = content_block.manifest.images.find do |image_config|
      image_config[:name].to_s == name.to_s
    end

    config = content_block.manifest.images.first if config.blank? && name.blank?

    return if config.blank?

    config[:uploader].constantize
  end
end

Decidim::ContentBlockAttachment.prepend(ContentBlockAttachmentExtends)
