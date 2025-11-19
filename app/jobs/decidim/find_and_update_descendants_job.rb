# frozen_string_literal: true

module Decidim
  class FindAndUpdateDescendantsJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 100

    def perform(element)
      process_element_and_descendants(element)
    end

    private

    def process_element_and_descendants(element)
      reindex_element(element)
      process_components(element)
      process_comments(element)
    end

    def reindex_element(element)
      return unless element.class.respond_to?(:searchable_resource?) && element.class.searchable_resource?(element)

      org = element.class.search_resource_fields_mapper.retrieve_organization(element)
      return unless org

      searchables_in_org = element.searchable_resources.by_organization(org.id)
      should_index = element.class.search_resource_fields_mapper.index_on_update?(element)

      if should_index
        if searchables_in_org.empty?
          element.add_to_index_as_search_resource
        else
          fields = element.class.search_resource_fields_mapper.mapped(element)
          searchables_in_org.find_each do |sr|
            next if sr.blank?

            attrs = element.send(:contents_to_searchable_resource_attributes, fields, sr.locale)
            sr.update_columns(attrs)
          end
        end
      elsif searchables_in_org.any?
        searchables_in_org.delete_all
      end
    end

    def process_components(element)
      return unless element.respond_to?(:components) && element.components.any?

      element.components.find_each do |component|
        klass = component_class(component)
        next unless valid_component_class?(klass)

        klass.where(component: component).find_in_batches(batch_size: BATCH_SIZE) do |batch|
          batch.each { |descendant| process_element_and_descendants(descendant) }
        end
      end
    end

    def process_comments(element)
      return unless element.respond_to?(:comments) && element.comments.any?

      element.comments.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        batch.each { |comment| process_element_and_descendants(comment) }
      end
    end

    def component_class(component)
      return Decidim::Blogs::Post if component.manifest_name == "blogs"

      manifest_name_to_class(component.manifest_name)
    end

    def manifest_name_to_class(name)
      resource_registry = Decidim.resource_registry.find(name)
      return if resource_registry.blank?

      resource_registry.model_class_name&.safe_constantize
    end

    def valid_component_class?(klass)
      klass.present? && klass.column_names.include?("decidim_component_id")
    end
  end
end
