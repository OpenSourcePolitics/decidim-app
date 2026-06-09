# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module ComponentTools
      extend ActiveSupport::Concern
      included do
        def component_resource_manifests(manifest_name)
          return [] if manifest_name.blank?

          Decidim.resource_registry.manifests.each.with_object([]) do |manifest, resources|
            resources.push(manifest) if manifest.component_manifest&.name == manifest_name.to_sym
          end
        end

        def component_commentable_resource_manifests(manifest_name)
          component_resource_manifests(manifest_name).select { |manifest| manifest.model_class_name&.constantize&.include?(Decidim::Comments::Commentable) }
        end

        def commentable_component?(manifest_name)
          component_commentable_resource_manifests(manifest_name).any?
        end

        def comments_for_component(component)
          component_commentable_resource_manifests(component&.manifest_name).each.with_object([]) do |manifest, results|
            results.concat(comments_for_resource(manifest.model_class_name.constantize, component)) if manifest.model_class_name.present?
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # Fix for Decidim::Comments::Export.comments_for_resource which only works for :belong_to associations
        def comments_for_resource(resource_class, component)
          reflection = resource_class.reflections["component"]

          if reflection.present?
            if reflection.belongs_to?
              # Meaning that the resource has something like :
              # belongs_to :component, foreign_key: "decidim_component_id", class_name: "Decidim::Component" ...
              root_commentable = resource_class.where(component:)
            elsif reflection.has_one? && reflection.try(:options)&.[](:through).present?
              # Meaning that the resource has something like :
              # has_one :component, through: < belongs_to association > ...
              through = reflection.options[:through]
              gateway_reflection = resource_class.reflections[through.to_s]
              gateway_resources = gateway_reflection.try(:options)&.[](:class_name)&.constantize&.where(component:)
              root_commentable = gateway_resources.present? ? resource_class.where(through => gateway_resources) : resource_class.none
            end
            if root_commentable.present?
              return Decidim::Comments::Comment
                     .not_deleted
                     .not_hidden
                     .where(root_commentable:)
            end
          end
          Rails.logger.warn "Decidim::Content::ComponentTools.comments_for_resource (concerns) : Unable to fetch comments for #{resource_class} with component association."
          Decidim::Comments::Comment.none
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
      end
    end
  end
end
