# frozen_string_literal: true

require "active_support/concern"
module DuplicateAssemblyExtends
  extend ActiveSupport::Concern

  included do
    def call
      return broadcast(:invalid) if form.invalid?

      Decidim.traceability.perform_action!("duplicate", @assembly, @user) do
        Decidim::Assembly.transaction do
          duplicate_assembly
          duplicate_assembly_attachments
          duplicate_assembly_components if @form.duplicate_components?
          duplicate_landing_page_blocks if @form.duplicate_landing_page_blocks?
        end
      end

      broadcast(:ok, @duplicated_assembly)
    end

    private

    def duplicate_landing_page_blocks
      blocks = Decidim::ContentBlock.where(scoped_resource_id: @assembly.id, scope_name: "assembly_homepage", organization: @assembly.organization)
      return if blocks.blank?

      blocks.each do |block|
        new_block = Decidim::ContentBlock.create!(
          organization: @duplicated_assembly.organization,
          scope_name: "assembly_homepage",
          scoped_resource_id: @duplicated_assembly.id,
          manifest_name: block.manifest_name,
          settings: block.settings,
          weight: block.weight,
          published_at: block.published_at.present? ? @duplicated_assembly.created_at : nil # determine if block is active/inactive
        )
        duplicate_block_attachments(block, new_block) if block.attachments.present?
      end
    end

    def duplicate_block_attachments(block, new_block)
      block.attachments.map(&:name).each do |name|
        original_image = block.images_container.send(name).blob
        next if original_image.blank?

        new_block.images_container.send("#{name}=", ActiveStorage::Blob.create_and_upload!(
                                                      io: StringIO.new(original_image.download),
                                                      filename: "image.png",
                                                      content_type: block.images_container.background_image.blob.content_type
                                                    ))
        new_block.save!
      end
    end

    def duplicate_assembly_components
      new_component_id = nil
      @assembly.components.each do |component|
        new_component = Decidim::Component.create!(
          manifest_name: component.manifest_name,
          name: component.name,
          participatory_space: @duplicated_assembly,
          settings: component.settings,
          step_settings: component.step_settings,
          weight: component.weight
        )
        new_component_id = new_component.id if new_component.manifest_name == "proposals"
        component.manifest.run_hooks(:duplicate, new_component:, old_component: component)
      end
      component_id = @assembly.components.where(manifest_name: "proposals")&.first&.id
      proposal_states = Decidim::Proposals::ProposalState.where(decidim_component_id: component_id) if component_id
      duplicate_proposal_states(proposal_states, new_component_id) if proposal_states
    end

    def duplicate_proposal_states(states, new_component_id)
      states.each do |state|
        Decidim::Proposals::ProposalState.create!(
          decidim_component_id: new_component_id,
          title: state.title,
          text_color: state.text_color,
          bg_color: state.bg_color,
          announcement_title: state.announcement_title,
          token: state.token
        )
      end
    end
  end
end

Decidim::Assemblies::Admin::DuplicateAssembly.include(DuplicateAssemblyExtends)
