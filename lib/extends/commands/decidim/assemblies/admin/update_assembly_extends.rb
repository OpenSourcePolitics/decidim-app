# frozen_string_literal: true

require "active_support/concern"
module UpdateAssemblyExtends
  extend ActiveSupport::Concern

  included do
    def attributes
      decidim_attributes = decidim_original_attributes
      location = resource.decidim_geo_space_location || Decidim::Geo::SpaceLocation.new
      location.address = form.decidim_geo_space_address
      location.latitude = form.latitude
      location.longitude = form.longitude
      decidim_attributes[:decidim_geo_space_location] = location
      decidim_attributes
    end
  end
end

Decidim::Assemblies::Admin::UpdateAssembly.include(UpdateAssemblyExtends)
