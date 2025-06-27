# frozen_string_literal: true

# This migration comes from decidim_geo (originally 20241008060901)
class IndexDecidimGeo < ActiveRecord::Migration[6.1]
  def change
    Decidim::Component.all.each do |model|
      model.decidim_geo_avoid_index ||= Decidim::Geo::NoIndex.new
      model.save
      model.update_decidim_geo_index
    end

    models = Decidim::Geo::ManifestRegistry.instance.active_manifests { |manifests| manifests.map { |_name, config| config[:model] } }
    models.each do |model_klass|
      Rails.logger.debug { "index class #{model_klass} " }
      model_klass.all.each do |item|
        item.update_decidim_geo_index
        Rails.logger.debug "."
      end
    end
  end
end
