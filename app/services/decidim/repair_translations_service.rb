# frozen_string_literal: true

module Decidim
  class RepairTranslationsService
    def initialize(logger: nil)
      @logger = logger || Rails.logger
    end

    def self.run(logger: nil)
      new(logger: logger).run
    end

    def run
      @logger.info("Found #{translatable_resources.size} translatable resources")
      updated_resources = []
      translatable_resources.each do |resources|
        @logger.info("Checking #{resources}...")
        @logger.info("Found #{resources.count} resources")
        resources.find_each do |resource|
          @logger.info("Checking #{resource}...")
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
      @translatable_resources ||= Decidim.resource_manifests.map(&:model_class).select do |resource|
        resource.respond_to?(:translatable_fields_list)
      end
    end

    def default_locale(resource)
      resource.try(:organization).try(:default_locale) || Decidim.default_locale
    end
  end
end
