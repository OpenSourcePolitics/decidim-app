# frozen_string_literal: true

# TODO: delete this extends when issue https://git.octree.ch/decidim/decidim-module-geo/-/issues/168 has been fixed

require "active_support/concern"

module UpdateComponentExtends
  extend ActiveSupport::Concern

  included do
    private

    def update_component
      decidim_original_update_component

      avoid_index_relation = @component.decidim_geo_avoid_index || Decidim::Geo::NoIndex.new
      avoid_index_relation.decidim_component_id = @component.id
      avoid_index_relation.no_index = form.decidim_geo_avoid_index.nil? ? false : form.decidim_geo_avoid_index
      @component.decidim_geo_avoid_index = avoid_index_relation
      @component.save!
      # Update geo index linked resources
      Decidim::Geo::Index.where(
        component_id: @component.id,
        resource_type: @component.manifest_name
      ).update(avoid_index: avoid_index_relation.no_index)
    end
  end
end

Decidim::Admin::UpdateComponent.include(UpdateComponentExtends)
