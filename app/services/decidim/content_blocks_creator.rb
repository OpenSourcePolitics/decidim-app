# frozen_string_literal: true

module Decidim
  # Service to generate content blocks on spaces o resources which have content
  # blocks registered for them on their engines.
  #
  # This class is initialized passing an space which can be an organization, a
  # participatory space with content blocks like processes or assemblies or a
  # participatory process group.
  class ContentBlocksCreator
    attr_reader :space, :scope_name, :scoped_resource_id, :is_organization, :organization, :default_content_blocks, :component_content_blocks

    def initialize(space)
      @space = space
      @is_organization = space.is_a? Decidim::Organization
      @organization = is_organization ? space : space.organization
      @scoped_resource_id = is_organization ? nil : space.id
      manifest = manifest_for(space)
      @scope_name = is_organization ? :homepage : manifest.content_blocks_scope_name
      raise ArgumentError, "[ERROR] The #{manifest.name} spaces do not define a content blocks scope" if scope_name.blank?

      @default_content_blocks = Decidim.content_blocks.for(scope_name).select(&:default)
      @component_content_blocks = Decidim.content_blocks.for(scope_name).select(&:component_manifest_name)
    end

    # Creates all content blocks registered as default for the space or
    # resource unless one created with the same manifest already exists in
    # the same space.
    def create_default!
      default_content_blocks.each_with_index do |manifest, index|
        next if Decidim::ContentBlock.exists?(decidim_organization_id: organization.id, scope_name:, manifest_name: manifest.name, scoped_resource_id:)

        order, inactive_parts = determine_order_and_inactive_parts(space)

        weight = calculate_weight(manifest.name, order, inactive_parts, index)
        published_at = inactive_parts.include?(manifest.name) ? nil : Time.current

        Decidim::ContentBlock.create(
          decidim_organization_id: organization.id,
          weight:,
          scope_name:,
          scoped_resource_id:,
          manifest_name: manifest.name,
          published_at:
        )
      end
    end

    # This method only works in participatory spaces. For all the components
    # published in the space creates an associated content block if registered
    # for the sope and component and is not created configured for the
    # component or globally to cover all components of the same type.
    def create_components_blocks!
      return unless space.is_a? Decidim::Participable

      space.components.published.each_with_index do |component, index|
        block_manifest = component_content_blocks.find { |manifest| manifest.component_manifest_name == component.manifest_name }

        next unless block_manifest

        content_blocks = Decidim::ContentBlock.where(decidim_organization_id: organization.id, scope_name:, manifest_name: block_manifest.name, scoped_resource_id:)

        # Ignore creation if there is already a content block for the same
        # component or a general content block for all the components of the
        # same type in the space
        next if content_blocks.any? do |block|
          component_id = block.settings.component_id
          component_id.blank? || component_id.to_i == component.id
        end

        weight = ((index + 1) * 10) + 1000

        Decidim::ContentBlock.create(
          decidim_organization_id: organization.id,
          weight:,
          scope_name:,
          scoped_resource_id:,
          manifest_name: block_manifest.name,
          settings: { component_id: component.id.to_s },
          published_at: Time.current
        )
      end
    end

    private

    def manifest_for(resource)
      return resource.manifest if resource.is_a? Decidim::Participable

      resource.resource_manifest if resource.is_a? Decidim::Resourceable
    end

    def determine_order_and_inactive_parts(space)
      case space
      when Decidim::ParticipatoryProcess, Decidim::Assembly
        [
          [:hero, :extra_data, :announcement, :main_data, :metadata, :related_documents,
           :highlighted_meetings, :highlighted_posts, :highlighted_proposals,
           :highlighted_results, :related_processes, :related_assemblies],
          [:html, :last_activity, :stats, :metrics, :related_images]
        ]
      when Decidim::ParticipatoryProcessGroup
        [
          [:hero, :title, :participatory_processes, :highlighted_meetings, :highlighted_proposals, :highlighted_results],
          # rubocop:disable Naming/VariableNumber
          [:html_1, :stats, :extra_data]
          # rubocop:enable Naming/VariableNumber
        ]
      else
        [[], []]
      end
    end

    def calculate_weight(manifest_name, order, inactive_parts, index)
      if inactive_parts.include?(manifest_name)
        (inactive_parts.index(manifest_name) + 1) * 10
      elsif order.include?(manifest_name)
        (order.index(manifest_name) + 1) * 10
      else
        (index + 1) * 10
      end
    end
  end
end
