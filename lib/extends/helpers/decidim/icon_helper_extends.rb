# frozen_string_literal: true

module IconHelperExtends
  def resource_icon(resource, options = {})
    if resource.instance_of?(Decidim::Initiative)
      icon "initiatives", options
    elsif resource.instance_of?(Decidim::Comments::Comment)
      icon "comment-square", options
    elsif resource.respond_to?(:component)
      component_icon(resource.component, options)
    elsif resource.respond_to?(:manifest)
      manifest_icon(resource.manifest, options)
    elsif resource.is_a?(Decidim::User)
      icon "person", options
    else
      icon "bell", options
    end
  end
end

Decidim::IconHelper.module_eval do
  prepend(IconHelperExtends)
end