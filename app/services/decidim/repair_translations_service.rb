# frozen_string_literal: true

module Decidim
  class RepairTranslationsService
    def self.run
      new.run
    end

    def run
      updated_resources = []
      translatable_resources.each do |resources|
        resources.find_each do |resource|
          updated_resources << [resource.class, resource.id] if repair_translations(resource)
        end
      end

      updated_resources
    end

    private

    # Translations is based on a diff between last changes and current changes
    # So we need to create a fake diff with the previous changes
    def translatable_previous_changes(resource)
      resource.slice(*resource.class.translatable_fields_list).transform_values { |value| [nil, value] }
    end

    def repair_translations(resource)
      Decidim::MachineTranslationResourceJob.perform_later(
        resource,
        translatable_previous_changes(resource),
        default_locale(resource)
      )
    end

    def translatable_resources
      Decidim.resource_manifests.map(&:model_class).select do |resource|
        resource.respond_to?(:translatable_fields_list)
      end
    end

    def default_locale(resource)
      resource.try(:organization).try(:default_locale) || Decidim.default_locale
    end
  end
end
