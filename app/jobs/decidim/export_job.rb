# frozen_string_literal: true

module Decidim
  class ExportJob < ApplicationJob
    queue_as :exports

    def perform(user, component, name, format, resource_id = nil, filters = nil) # rubocop:disable Metrics/ParameterLists
      export_manifest = component.manifest.export_manifests.find do |manifest|
        manifest.name == name.to_sym
      end

      collection = export_manifest.collection.call(component, user, resource_id)
      collection = collection.ransack(filters).result if collection.respond_to?(:ransack) && filters
      serializer = export_manifest.serializer

      export_data = if (serializer == Decidim::Proposals::ProposalSerializer) && (user.admin? || admin_of_process?(user, component) || admin_of_assembly?(user, component))
                      Decidim::Exporters.find_exporter(format).new(collection, serializer).admin_export
                    else
                      Decidim::Exporters.find_exporter(format).new(collection, serializer).export
                    end
      ExportMailer.export(user, name, export_data).deliver_now
    end

    private

    def admin_of_process?(user, component)
      return false unless component.respond_to?(:participatory_space)

      Decidim::ParticipatoryProcessUserRole.exists?(decidim_user_id: user.id, decidim_participatory_process_id: component.participatory_space.id, role: "admin")
    end

    def admin_of_assembly?(user, component)
      return false unless component.respond_to?(:participatory_space)

      Decidim::AssemblyUserRole.exists?(decidim_user_id: user.id, decidim_assembly_id: component.participatory_space.id, role: "admin")
    end
  end
end
