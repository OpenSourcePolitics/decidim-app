# frozen_string_literal: true

require "digest"

module ProjectListItemCellExtends
  def vote_button_disabled?
    !can_have_order?
  end

  def perform_caching?
    %w(all list_cache).include? request.headers["X-FEATURE-FLAG"]
  end

  def cache_hash
    hash = []
    hash.push(model.cache_version)
    hash.push(model.photos.first.cache_version) if model.photos.any?
    hash.push(model&.category.try(:cache_version))

    hash.push(current_order&.can_checkout? ? :can_checkout : :cannot_checkout)
    hash.push(resource_added?)
    hash.push(can_have_order?)

    hash.push(I18n.locale)
    hash.push(current_settings)

    Digest::MD5.hexdigest(hash.join(Decidim.cache_key_separator))
  end
end

Decidim::Budgets::ProjectListItemCell.class_eval do
  prepend(ProjectListItemCellExtends)
end
