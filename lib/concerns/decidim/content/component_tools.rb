# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module ComponentTools
      extend ActiveSupport::Concern
      included do
        include Decidim::Content::UidTools

        def component_resource_cache
          @component_resource_cache ||= Hash.new { |h, k| h[k] = h.dup.clear }
        end

        def component_resource_cache_set(container:, resource_class:, query:, force: false)
          if force || component_resource_cache[uid(container)][resource_class.name].blank?
            component_resource_cache[uid(container)][resource_class.name] = query
          else
            component_resource_cache[uid(container)][resource_class.name]
          end
        end

        def component_resource_cache_get(container:, resource_class:)
          (component_resource_cache[uid(container)][resource_class.name].presence || resource_class.none)
        end

        def component_resource_cache_exists?(container:, resource_class:)
          component_resource_cache[uid(container)][resource_class.name].present?
        end

        def component_resource_manifests(manifest_name)
          return [] if manifest_name.blank?

          Decidim.resource_registry.manifests.each.with_object([]) do |manifest, resources|
            resources.push(manifest) if manifest.component_manifest&.name == manifest_name.to_sym
          end
        end

        def component_resource_manifests_including_trait(manifest_name, trait_module)
          component_resource_manifests(manifest_name).select { |manifest| manifest.model_class_name&.constantize&.include?(trait_module) }
        end

        def endorsable_component?(manifest_name)
          component_resource_manifests_including_trait(manifest_name, Decidim::Endorsable).any?
        end

        def followable_component?(manifest_name)
          component_resource_manifests_including_trait(manifest_name, Decidim::Followable).any?
        end

        def component_has_attachments?(manifest_name)
          component_resource_manifests_including_trait(manifest_name, Decidim::HasAttachments).any?
        end

        def commentable_component?(manifest_name)
          component_resource_manifests_including_trait(manifest_name, Decidim::Comments::Commentable).any?
        end

        def comments_for_component(component)
          component_resource_manifests_including_trait(component&.manifest_name, Decidim::Comments::Commentable).each.with_object([]) do |manifest, results|
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

            if component_resource_cache_exists?(container: component, resource_class:)
              cached_ids = component_resource_cache_get(container: component, resource_class:).pluck(:id)
              root_commentable = root_commentable.where(id: cached_ids)
            end

            if root_commentable.present?
              return Decidim::Comments::Comment
                     .not_deleted
                     .not_hidden
                     .where(root_commentable:)
            end
          end
          Rails.logger.warn "Decidim::Content::ComponentTools.comments_for_resource (concerns) : No comments found for #{resource_class} with component association."
          Rails.logger.warn "-- cached query was involved with #{cached_ids.size} records" if component_resource_cache_exists?(container: component, resource_class:)
          Decidim::Comments::Comment.none
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity

        def endorsements_for_component(component)
          component_resource_manifests_including_trait(component&.manifest_name, Decidim::Endorsable).each.with_object([]) do |manifest, results|
            results.concat(endorsements_for_resource(manifest.model_class_name.constantize, component)) if manifest.model_class_name.present?
          end
        end

        def endorsements_for_resource(resource_class, component)
          endorsable_resources = resource_class.where(component:)
          if component_resource_cache_exists?(component:, resource_class:)
            cached_ids = component_resource_cache_get(component:, resource_class:).pluck(:id)
            endorsable_resources = endorsable_resources.where(id: cached_ids)
          end
          return Decidim::Endorsement.where(resource: endorsable_resources) if endorsable_resources.present?

          Rails.logger.warn "Decidim::Content::ComponentTools.endorsements_for_resource (concerns) : No endorsements found for #{resource_class} with component association."
          Rails.logger.warn "-- cached query was involved with #{cached_ids.size} records" if component_resource_cache_exists?(component:, resource_class:)
          Decidim::Endorsement.none
        end

        def followers_for_component(component)
          component_resource_manifests_including_trait(component&.manifest_name, Decidim::Followable).each.with_object([]) do |manifest, results|
            results.concat(followers_for_resource(manifest.model_class_name.constantize, component)) if manifest.model_class_name.present?
          end
        end

        def followers_for_resource(resource_class, component)
          followable_resources = resource_class.where(component:)
          if component_resource_cache_exists?(component:, resource_class:)
            cached_ids = component_resource_cache_get(component:, resource_class:).pluck(:id)
            followable_resources = followable_resources.where(id: cached_ids)
          end
          return Decidim::Follow.where(followable: followable_resources) if followable_resources.present?

          Rails.logger.warn "Decidim::Content::ComponentTools.followers_for_resource (concerns) : No followers found for #{resource_class} with component association."
          Rails.logger.warn "-- cached query was involved with #{cached_ids.size} records" if component_resource_cache_exists?(component:, resource_class:)
          Decidim::Follow.none
        end

        def attachment_collections_for_component(component)
          component_resource_manifests_including_trait(component&.manifest_name, Decidim::HasAttachments).each.with_object([]) do |manifest, results|
            results.concat(attachment_collections_for_resource(manifest.model_class_name.constantize, component)) if manifest.model_class_name.present?
          end
        end

        def attachment_collections_for_resource(resource_class, component)
          attachable_resources = resource_class.where(component:)
          if component_resource_cache_exists?(component:, resource_class:)
            cached_ids = component_resource_cache_get(component:, resource_class:).pluck(:id)
            attachable_resources = attachable_resources.where(id: cached_ids)
          end
          return Decidim::AttachmentCollection.where(collection_for: attachable_resources) if attachable_resources.present?

          Rails.logger.warn do
            "Decidim::Content::ComponentTools.attachment_collections_for_resource (concerns) : No attachment collections found for #{resource_class} with component association."
          end
          Rails.logger.warn "-- cached query was involved with #{cached_ids.size} records" if component_resource_cache_exists?(component:, resource_class:)
          Decidim::AttachmentCollection.none
        end

        def attachments_for_component(component)
          component_resource_manifests_including_trait(component&.manifest_name, Decidim::HasAttachments).each.with_object([]) do |manifest, results|
            results.concat(attachments_for_resource(manifest.model_class_name.constantize, component)) if manifest.model_class_name.present?
          end
        end

        def attachments_for_resource(resource_class, component)
          attachable_resources = resource_class.where(component:)
          if component_resource_cache_exists?(component:, resource_class:)
            cached_ids = component_resource_cache_get(component:, resource_class:).pluck(:id)
            attachable_resources = attachable_resources.where(id: cached_ids)
          end
          return Decidim::Attachment.where(attached_to: attachable_resources) if attachable_resources.present?

          Rails.logger.warn "Decidim::Content::ComponentTools.attachments_for_resource (concerns) : No attachments found for #{resource_class} with component association."
          Rails.logger.warn "-- cached query was involved with #{cached_ids.size} records" if component_resource_cache_exists?(component:, resource_class:)
          Decidim::Attachment.none
        end

        def proposals_for_component(component)
          component_resource_cache_set(
            container: component,
            resource_class: Decidim::Proposals::Proposal,
            query: Decidim::Proposals::Proposal
                    .published
                    .not_hidden
                    .where(component:)
          )
        end

        def debates_for_component(component)
          component_resource_cache_set(
            container: component,
            resource_class: Decidim::Debates::Debate,
            query: Decidim::Debates::Debate
                    .not_hidden
                    .where(component:)
          )
        end

        def accountability_results_for_component(component)
          component_resource_cache_set(
            container: component,
            resource_class: Decidim::Accountability::Result,
            query: Decidim::Accountability::Result.where(component:).order("children_count DESC, parent_id ASC, id ASC")
          )
        end

        def projects_for_budget(budget)
          component_resource_cache_set(
            container: budget,
            resource_class: Decidim::Budgets::Project,
            query: Decidim::Budgets::Project.where(budget:)
          )
        end
      end
    end
  end
end
