# frozen_string_literal: true

require "active_support/concern"

module ContentBlockFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :images, Hash
  end

  def map_model(model)
    @images_container = model.images_container
    self.images = {}
  end

  def images=(value)
    if value.is_a?(Hash)
      super(value.transform_keys(&:to_sym))
    else
      @images_container = value
      super({})
    end
  end

  def images
    @images_container ||= begin
      cb_id = id.presence
      if cb_id
        scope = context.try(:current_participatory_space)
        cb = scope ? Decidim::ContentBlock.find_by(id: cb_id, scoped_resource_id: scope.id) : Decidim::ContentBlock.find_by(id: cb_id)
        cb&.images_container
      end
    end
  end

  def image_params
    attributes["images"] || {}
  end
end

Decidim::Admin::ContentBlockForm.include(ContentBlockFormExtends)
