# frozen_string_literal: true

require "csv"
require "stringio"

module Decidim
  module Content
    class TreeGenerator
      include Decidim::TranslatableAttributes
      include Decidim::Content::MetadataGenerator
      include Decidim::Content::LocationGenerator

      SUPPORTED_PARTICIPATORY_SPACES = [
        {
          space_class: Decidim::ParticipatoryProcess,
          space_eager_load: [:organization, :components],
          space_icon: "treasure-map-line",
          group_class: Decidim::ParticipatoryProcessGroup,
          group_attribute: :decidim_participatory_process_group_id
        },
        {
          space_class: Decidim::Assembly,
          space_eager_load: [:organization, :categories, :attachments, :components],
          space_icon: "government-line",
          group_class: Decidim::Assembly,
          group_attribute: :parent_id,
          group_eager_load: [:organization, :categories, :attachments, :components],
          group_icon: "government-line",
          sub_group_class: Decidim::Assembly,
          sub_group_attribute: :parent_id,
          sub_group_eager_load: [:organization, :categories, :attachments, :components],
          sub_group_icon: "government-line"
        },
        {
          space_class: Decidim::Initiative,
          space_eager_load: [:organization, :components],
          space_icon: "lightbulb-flash-line",
          group_class: Decidim::InitiativesType,
          group_attribute: :decidim_initiatives_types_id,
          group_icon: "layout-masonry-line",
          sub_group_class: Decidim::InitiativesTypeScope,
          sub_group_attribute: :scoped_type_id,
          sub_group_eager_load: [:scope],
          sub_group_icon: "price-tag-3-line"
        },
        {
          space_class: Decidim::Conference,
          space_eager_load: [:organization, :components],
          space_icon: "live-line"
        }
      ].freeze

      SUPPORTED_NAME_ATTRIBUTES = %w(
        name
        title
        scope.name
        type.name
      ).freeze

      DEFAULT_KIND_ICONS = {
        root: "home-2-line",
        type: "price-tag-3-line",
        group: "folder-line",
        sub_group: "folder-line",
        space: "pages-line",
        component: "focus-line"
      }.freeze

      DEFAULT_OPTIONS = {
        include_components: true,
        include_object: true,
        include_location: true,
        location_type: :path,
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
        shared_hash(instance: organization, kind: "root", manifest: {}).merge(
          children: SUPPORTED_PARTICIPATORY_SPACES.map do |manifest|
            {
              kind: "type",
              name: manifest[:space_class].model_name.human(count: :other),
              manifest:,
              children: children = build_participatory_spaces_array(manifest)
            }.merge(
              item_count: count_space_children(children)
            )
          end
        ) { |_key, old_value, new_value| old_value + new_value }
      end

      def to_csv
        rows = flatten_hash_for_csv(hash)

        forced_headers = [:kind, :group, :sub_group, :space, :class, :component_type, :name, :private, :published, :item_count, :stats, :url, :admin_url, :gid]
        rejected_headers = [:manifest]

        headers_row_hash = rows.each_with_object([]) do |row, keys|
          row.keys.each { |key| keys << key unless keys.include?(key) }
        end

        headers = forced_headers.union(headers_row_hash).difference(rejected_headers)

        csv_data = ::CSV.generate(headers:, write_headers: true, col_sep: Decidim.default_csv_col_sep) do |csv|
          rows.each do |row|
            csv << headers.map { |header| sanitize_csv_value(row[header]) }
          end
        end

        ::StringIO.new(csv_data)
      end

      private

      def participatory_spaces_base_query(manifest)
        manifest[:space_class].includes(manifest[:space_eager_load] || []).where(organization:)
      end

      def build_participatory_spaces_array(manifest)
        result = []
        space_query = participatory_spaces_base_query(manifest)
        if manifest[:group_class].present?
          result += build_groups_array(manifest)

          # Get spaces that are not in any group
          if manifest[:space_class] != manifest[:group_class] && manifest[:space_class].has_attribute?(manifest[:group_attribute])
            result += space_query.where(manifest[:group_attribute] => nil).map do |space|
              shared_hash(instance: space, kind: "space", manifest:)
            end
          end
        else
          space_query.each do |space|
            space_hash = shared_hash(instance: space, kind: "space", manifest:)
            result << space_hash
          end
        end
        result
      end

      def build_groups_array(manifest)
        group_query = manifest[:group_class].includes(manifest[:group_eager_load] || []).where(organization:)

        # If groups and spaces are the same class like Assemblies,
        # we only want to get top level groups (group_attribute not set) in this query
        group_query = group_query.where(manifest[:group_attribute] => nil) if manifest[:space_class] == manifest[:group_class]

        group_query.map do |group|
          build_group_hash(manifest, group)
        end
      end

      def build_group_hash(manifest, group)
        group_hash = shared_hash(instance: group, kind: "group", manifest:)

        group_hash[:children] = [] if group_hash[:children].nil?

        # Get sub groups if applicable
        group_hash[:children] += build_sub_groups_array(manifest, group) if manifest[:sub_group_class].present?

        # Get group spaces that are not in any sub-group
        if manifest[:space_class] != manifest[:group_class] && manifest[:space_class].has_attribute?(manifest[:group_attribute])
          group_hash[:children] += participatory_spaces_base_query(manifest).where(manifest[:group_attribute] => group.id).map do |space|
            shared_hash(instance: space, kind: "space", manifest:)
          end
        end
        group_hash[:item_count] = count_space_children(group_hash[:children]) if group_hash[:children].present?
        group_hash
      end

      def build_sub_groups_array(manifest, group)
        # If sub-groups and spaces are the same class like Assemblies, we treat spaces like sub-groups.
        # Both are directly part of the parent group and will be fetched by the same query
        manifest[:sub_group_class].includes(manifest[:sub_group_eager_load] || []).where(manifest[:group_attribute] => group.id).map do |sub_group|
          build_sub_group_hash(manifest, sub_group)
        end
      end

      def build_sub_group_hash(manifest, sub_group)
        shared_hash(instance: sub_group, kind: "sub_group", manifest:).merge(
          {
            children: children = manifest[:space_class].includes(manifest[:sub_group_eager_load] || []).where(manifest[:sub_group_attribute] => sub_group.id).map do |space|
              shared_hash(instance: space, kind: "space", manifest:)
            end
          }.merge(
            item_count: count_space_children(children)
          )
        ) { |_key, old_value, new_value| old_value + new_value }
      end

      def build_components_array(instance)
        return {} unless instance.respond_to?(:components) && instance.components.any?

        if options[:components_as_children]
          components_attribute = :children
          count_attribute = :item_count
        else
          components_attribute = :components
          count_attribute = :component_count
        end
        {
          components_attribute.to_sym => children = instance.components.map do |component|
            shared_hash(instance: component, kind: "component", manifest: instance.manifest.to_h, icon: component.manifest.icon_key).merge(
              {
                item_count: component.primary_stat,
                value: component.primary_stat || 1 # TODO : remove if unnecessary
              }
            )
          end
        }.merge(count_attribute => children.size)
      end

      def shared_hash(instance:, kind:, manifest:, icon: nil)
        result_hash = {
          kind:,
          manifest:,
          class: instance.class.name,
          gid: instance.to_global_id.to_s,
          name: name_attribute(instance) ||
                "-- #{instance.class.name}(ID:#{instance.id}) --"
        }
        icon = icon.presence || manifest["#{kind}_icon".to_sym].presence || DEFAULT_KIND_ICONS[kind.to_sym]
        result_hash[:icon] = icon if icon.present?
        result_hash[:object] = instance if options[:include_object]
        result_hash.merge!(location_for(instance, options[:location_type])) if options[:include_location]
        result_hash[:metadata] = metadata_for(instance) if options[:include_metadata]
        result_hash.merge!(build_components_array(instance)) if options[:include_components]
        result_hash
      end

      def name_attribute(instance)
        SUPPORTED_NAME_ATTRIBUTES.each do |attribute|
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
          flatten_root_for_csv(tree, row_prefix_values)
        when "group", "sub_group"
          flatten_group_for_csv(tree, row_prefix_values)
        when "space"
          flatten_space_for_csv(tree, row_prefix_values)
        when "component"
          [flatten_row_hash_for_csv(tree).merge(row_prefix_values)]
        end
      end

      def flatten_root_for_csv(tree, row_prefix_values)
        tree[:children].map do |space_type|
          space_type[:children].map do |space|
            flatten_hash_for_csv(space, row_prefix_values)
          end.flatten
        end.flatten
      end

      def flatten_group_for_csv(tree, row_prefix_values)
        [flatten_row_hash_for_csv(tree).merge(row_prefix_values)].concat(
          tree[:children].map do |children|
            flatten_hash_for_csv(
              children,
              row_prefix_values.merge(tree[:kind].to_sym => format_path_name_for_csv(tree))
            )
          end.flatten
        )
      end

      def flatten_space_for_csv(tree, row_prefix_values)
        result = [flatten_row_hash_for_csv(tree).merge(row_prefix_values)]
        return result unless options[:include_components]

        component_property = options[:components_as_children] ? :children : :components
        return result if tree[component_property].blank?

        result.concat(
          tree[component_property].map do |component|
            flatten_hash_for_csv(
              component,
              row_prefix_values.merge(space: format_path_name_for_csv(tree))
            )
          end.flatten
        )
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
        metadata[:labels].transform_values do |value|
          if value.is_a?(Hash) && value[:value].present?
            value[:value]
          else
            value
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

      def count_space_children(children_array)
        return 0 if children_array.blank?

        children_array.reduce(0) do |sum, child|
          item_count = if child[:item_count].to_i.positive?
                         child[:item_count].to_i + (spaceable_group?(child) ? 1 : 0)
                       elsif child[:kind] == "space" || spaceable_group?(child)
                         1
                       else
                         0
                       end
          sum + item_count
        end
      end

      def spaceable_group?(node)
        %w(group sub_group).include?(node[:kind]) &&
          node[:manifest].present? &&
          node[:manifest]["#{node[:kind]}_class".to_sym] == node[:manifest][:space_class]
      end
    end
  end
end
