# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ScopesHelperOverride
      extend ActiveSupport::Concern

      included do
        def scopes_picker_field(form, name, root: false, options: { checkboxes_on_top: true, sort_by_weight: true })
          options.merge!(selected: selected_scope(form)) if selected_scope(form)
          form.select(name, simple_scope_options(root: root, options: options), include_blank: t("decidim.scopes.prompt"))
        end

        private

        def selected_scope(form)
          form.try(:scope_id) ||
            form.try(:settings).try(:scope_id) ||
            form.try(:object).try(:scope_id) ||
            form.try(:object).try(:decidim_scope_id)
        end

        def simple_scope_options(root: false, options: {})
          scopes_array = []
          roots = root ? root.children : ancestors

          roots.sort_by { |ancestor| ancestor.weight || 0 }.each do |ancestor|
            children_after_parent(ancestor, scopes_array, "")
          end

          selected = options.has_key?(:selected) ? options[:selected] : params.dig(:filter, :decidim_scope_id)
          options_for_select(scopes_array, selected)
        end

        def ancestors
          @ancestors ||= current_organization.scopes.where(parent_id: nil)
        end

        def children_after_parent(ancestor, array, prefix)
          array << ["#{prefix} #{translated_attribute(ancestor.name)}", ancestor.id, ancestor.weight]
          ancestor.children.sort_by { |child| child.weight || 0 }.each do |child|
            children_after_parent(child, array, "#{prefix}-")
          end
        end
      end
    end
  end
end
