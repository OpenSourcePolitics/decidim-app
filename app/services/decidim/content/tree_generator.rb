# frozen_string_literal: true

require "csv"
require "stringio"

module Decidim
  module Content
    class TreeGenerator
      include Decidim::TranslatableAttributes
      include Decidim::Content::MetadataGenerator

      SUPPORTED_PARTICIPATORY_SPACES = [
        {
          space_class: Decidim::ParticipatoryProcess,
          group_class: Decidim::ParticipatoryProcessGroup,
          group_attribute: :decidim_participatory_process_group_id
        },
        {
          space_class: Decidim::Assembly,
          group_class: Decidim::Assembly,
          group_attribute: :parent_id,
          sub_group_class: Decidim::Assembly,
          sub_group_attribute: :parent_id
        },
        {
          space_class: Decidim::Initiative,
          group_class: Decidim::InitiativesType,
          group_attribute: :decidim_initiatives_types_id,
          sub_group_class: Decidim::InitiativesTypeScope,
          sub_group_attribute: :scoped_type_id
        },
        {
          space_class: Decidim::Conference
        }
      ].freeze

      SUPPPORTED_NAME_ATTRIBUTES = %w(
        name
        title
        scope.name
        type.name
      ).freeze

      DEFAULT_KIND_ICONS = {
        root: "home-2-line",
        type: "price-tag-3-line",
        group: "stack-line",
        sub_group: "stack-line",
        space: "pages-line",
        component: "apps-2-line"
      }

      DEFAULT_OPTIONS = {
        include_components: true,
        include_object: true,
        include_metadata: true,
        include_score: false,
        components_as_children: false
      }.freeze

      attr_reader :organization, :hash, :options

      def initialize(organization:, **options)
        @organization = organization
        @options = DEFAULT_OPTIONS.merge(options)
        @hash = build_tree
      end

      def build_tree
        shared_hash(instance: organization, kind: "root").merge(
          children: SUPPORTED_PARTICIPATORY_SPACES.map do |manifest|
            {
              kind: "type",
              name: manifest[:space_class].model_name.human(count: :other),
              manifest:,
              children: build_participatory_spaces_array(manifest)
            }
          end
        ) { |_key, old_value, new_value| old_value + new_value }
      end

      def to_csv
        rows = flatten_hash_for_csv(hash)
        
        forced_headers = %i(kind group sub_group space class component_type name private published item_count stats)
        headers_row_hash = rows.each_with_object([]) do |row, keys|
          row.keys.each { |key| keys << key unless keys.include?(key) }
        end

        headers = forced_headers.union(headers_row_hash)

        csv_data = ::CSV.generate(headers:, write_headers: true, col_sep: Decidim.default_csv_col_sep) do |csv|
          rows.each do |row|
            csv << headers.map { |header| sanitize_csv_value(row[header]) }
          end
        end

        ::StringIO.new(csv_data)
      end

      private

      def participatory_spaces_base_query(manifest)
        manifest[:space_class].where(organization:)
      end

      def build_participatory_spaces_array(manifest)
        result = []
        space_query = participatory_spaces_base_query(manifest)
        if manifest[:group_class].present?
          result += build_groups_array(manifest)

          # Get spaces that are not in any group
          if manifest[:space_class] != manifest[:group_class] && manifest[:space_class].has_attribute?(manifest[:group_attribute])
            result += space_query.where(manifest[:group_attribute] => nil).map do |space|
              shared_hash(instance: space, kind: "space")
            end
          end
        else
          space_query.each do |space|
            space_hash = shared_hash(instance: space, kind: "space")
            result << space_hash
          end
        end
        result
      end

      def build_groups_array(manifest)
        group_query = manifest[:group_class].where(organization:)

        # If groups and spaces are the same class like Assemblies,
        # we only want to get top level groups (group_attribute not set) in this query
        group_query = group_query.where(manifest[:group_attribute] => nil) if manifest[:space_class] == manifest[:group_class]

        group_query.map do |group|
          build_group_hash(manifest, group)
        end
      end

      def build_group_hash(manifest, group)
        group_hash = shared_hash(instance: group, kind: "group")

        group_hash[:children] = [] if group_hash[:children].nil?

        # Get sub groups if applicable
        group_hash[:children] += build_sub_groups_array(manifest, group) if manifest[:sub_group_class].present?

        # Get group spaces that are not in any sub-group
        if manifest[:space_class] != manifest[:group_class] && manifest[:space_class].has_attribute?(manifest[:group_attribute])
          group_hash[:children] += participatory_spaces_base_query(manifest).where(manifest[:group_attribute] => group.id).map do |space|
            shared_hash(instance: space, kind: "space")
          end
        end
        group_hash
      end

      def build_sub_groups_array(manifest, group)
        # If sub-groups and spaces are the same class like Assemblies, we treat spaces like sub-groups.
        # Both are directly part of the parent group and will be fetched by the same query
        manifest[:sub_group_class].where(manifest[:group_attribute] => group.id).map do |sub_group|
          build_sub_group_hash(manifest, sub_group)
        end
      end

      def build_sub_group_hash(manifest, sub_group)
        shared_hash(instance: sub_group, kind: "sub_group").merge(
          {
            children: manifest[:space_class].where(manifest[:sub_group_attribute] => sub_group.id).map do |space|
              shared_hash(instance: space, kind: "space")
            end
          }
        ) { |_key, old_value, new_value| old_value + new_value }
      end

      def build_components_array(instance)
        return {} unless instance.respond_to?(:components) && instance.components.any?

        components_attribute = options[:components_as_children] ? :children : :components
        {
          components_attribute.to_sym => instance.components.map do |component|
            shared_hash(instance: component, kind: "component").merge(
              {
                item_count: component.primary_stat,
                value: component.primary_stat || 1
              }
            )
          end
        }
      end

      def shared_hash(instance:, kind:, icon: nil)
        result_hash = {
          kind:,
          class: instance.class.name,
          name: name_attribute(instance) ||
                "-- #{instance.class.name}(ID:#{instance.id}) --"
        }
        if icon.present?
          result_hash[:icon] = icon
        elsif DEFAULT_KIND_ICONS[kind.to_sym].present?
          result_hash[:icon] = DEFAULT_KIND_ICONS[kind.to_sym]
        end
        result_hash[:object] = instance if options[:include_object]
        result_hash[:metadata] = metadata_for(instance) if options[:include_metadata]
        result_hash.merge!(build_components_array(instance)) if options[:include_components]
        result_hash
      end

      def name_attribute(instance)
        SUPPPORTED_NAME_ATTRIBUTES.each do |attribute|
          path = attribute.split(".")
          o = instance
          while !path.empty? && o.respond_to?(path.first) && o.send(path.first).present?
            o = o.send(path.first)
            return translated_attribute(o) if path.size == 1

            path = path.drop(1)
          end
        end
      end

      def current_locale
        I18n.locale.to_s.presence || organization&.default_locale
      end

      def flatten_hash_for_csv(tree, row_prefix_values = {})
        return unless tree.is_a?(Hash)

        case tree[:kind]
        when "root"
          tree[:children].map do |space_type|
            space_type[:children].map do |space|
              flatten_hash_for_csv(space, row_prefix_values)
            end.flatten
          end.flatten
        when "group", "sub_group"
          [flatten_row_hash_for_csv(tree).merge(row_prefix_values)].concat(
            tree[:children].map do |children|
              flatten_hash_for_csv(
                children, 
                row_prefix_values.merge(tree[:kind].to_sym => format_path_name_for_csv(tree))
              )
            end.flatten
          )
        when "space"
          result = [flatten_row_hash_for_csv(tree).merge(row_prefix_values)]
          if options[:include_components]
            component_property = options[:components_as_children] ? :children : :components
            if tree[component_property].present?
              result.concat(
                tree[component_property].map do |component|
                  flatten_hash_for_csv(
                    component, 
                    row_prefix_values.merge(space: format_path_name_for_csv(tree))
                  )
                end.flatten
              )
            end
          end
          result
        when "component"
          [flatten_row_hash_for_csv(tree).merge(row_prefix_values)]
        end
      end

      def flatten_row_hash_for_csv(row_hash)
        result = row_hash.except(:object, :children, :icon, :metadata, :value)
        result[:class] = row_hash[:class].demodulize if row_hash[:class].present?
        if options[:include_metadata]
          result.merge!(flatten_metadata_labels(row_hash[:metadata] || {}))
          result.merge!(flatten_metadata_stats(row_hash[:metadata] || {}))
        end
        result
      end

      def flatten_metadata_labels(metadata)
        metadata[:labels].each_with_object({}) do |(key, value), result|
          if value.is_a?(Hash) && value[:text].present?
            result[key] = value[:text]
          else
            result[key] = value
          end
        end
      end

      def flatten_metadata_stats(metadata, separator: "\n")
        {
          stats: metadata[:stats].values.map do |stat|
            if stat.is_a?(Hash) && stat[:text].present? && stat[:value].present?
              "#{stat[:value]} #{stat[:text]}"
            else
              stat.to_s
            end
          end.join(separator)
        }
      end

      def format_path_name_for_csv(tree)
        "[ #{tree[:class].demodulize} ] #{tree[:name]}"
      end

      def sanitize_csv_value(value)
        return value unless value.instance_of?(String) && %w(= + - @).include?(value.first)

        value.dup.prepend("'")
      end
    end
  end
end
