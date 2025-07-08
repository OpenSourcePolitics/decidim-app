# frozen_string_literal: true

# TODO, delete this extends when issue
# https://git.octree.ch/decidim/decidim-module-geo/-/issues?show=eyJpaWQiOiIxNjciLCJmdWxsX3BhdGgiOiJkZWNpZGltL2RlY2lkaW0tbW9kdWxlLWdlbyIsImlkIjo0OTE2fQ%3D%3D
# has been fixed

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
