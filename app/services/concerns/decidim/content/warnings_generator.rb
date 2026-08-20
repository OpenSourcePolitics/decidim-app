# frozen_string_literal: true

module Decidim
  module Content
    module WarningsGenerator
      extend ActiveSupport::Concern

      included do
        def warnings_for(instance)
          warnings = {}
          warnings.merge!(component_warnings(instance)) if instance.is_a?(Decidim::Component)
          warnings.merge!(assembly_warnings(instance)) if instance.is_a?(Decidim::Assembly)
          warnings.merge!(assemblies_warnings) if instance.is_a?(Hash) && instance[:space_class] == Decidim::Assembly
          warnings
        end
      end

      def component_warnings(component)
        {}.tap do |warnings|
          if component.permissions.present?
            warnings[:permissions] = {
              value: component.permissions.keys.size,
              text: I18n.t("decidim.admin.content.tree.warnings.component.permissions"),
              icon: "key-2-line",
              level: :warning
            }
          end
        end
      end

      def assembly_warnings(assembly)
        {}.tap do |warnings|
          if (subassemblies_count = Decidim::Assembly.where(parent_id: assembly.id).count).positive?
            warnings[:subassemblies] = {
              value: subassemblies_count,
              text: I18n.t("decidim.admin.content.tree.warnings.assembly.subassemblies"),
              icon: "folder-line",
              level: :warning
            }
          end
        end
      end

      def assemblies_warnings
        {}.tap do |warnings|
          max_depth = ActiveRecord::Base.connection.execute(Decidim::Assembly.select("nlevel(parents_path) AS depth").order("depth DESC").to_sql).pick("depth") || 0
          if max_depth > 1
            warnings[:subassemblies_depth] = {
              value: max_depth,
              text: I18n.t("decidim.admin.content.tree.warnings.assembly.subassemblies_depth", depth: max_depth),
              icon: "folder-line",
              level: :warning
            }
          end
        end
      end
    end
  end
end
