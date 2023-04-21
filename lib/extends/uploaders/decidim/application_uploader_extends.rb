# frozen_string_literal: true

module ApplicationUploaderExtends
  def variant(key)
    if key && variants[key].present?
      model.send(mounted_as).variant(variants[key])
    else
      model.send(mounted_as)
    end
  rescue ActiveStorage::InvariableError
    model.send(mounted_as)
  end
end

Decidim::ApplicationUploader.class_eval do
  prepend(ApplicationUploaderExtends)
end
