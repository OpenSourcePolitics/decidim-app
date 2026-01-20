# frozen_string_literal: true

require "active_support/concern"
module DuplicateParticipatoryProcessExtends
  extend ActiveSupport::Concern

  included do
    def call
      return broadcast(:invalid) if form.invalid?

      Decidim.traceability.perform_action!("duplicate", @participatory_process, current_user) do
        Decidim::ParticipatoryProcess.transaction do
          copy_participatory_process
          copy_participatory_process_attachments
          copy_participatory_process_steps if @form.copy_steps?
          copy_participatory_process_categories if @form.copy_categories?
          copy_participatory_process_components if @form.copy_components?
          copy_landing_page_blocks if @form.copy_landing_page_blocks?
        end
      end

      broadcast(:ok, @copied_process)
    end

    private

    def copy_landing_page_blocks
      blocks = Decidim::ContentBlock.where(scoped_resource_id: @participatory_process.id, scope_name: "participatory_process_homepage",
                                           organization: @participatory_process.organization)
      return if blocks.blank?

      blocks.each do |block|
        new_block = Decidim::ContentBlock.create!(
          organization: @copied_process.organization,
          scope_name: "participatory_process_homepage",
          scoped_resource_id: @copied_process.id,
          manifest_name: block.manifest_name,
          settings: block.settings,
          weight: block.weight,
          published_at: block.published_at.present? ? @copied_process.created_at : nil # determine if block is active/inactive
        )
        copy_block_attachments(block, new_block) if block.attachments.present?
      end
    end

    def copy_block_attachments(block, new_block)
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

    def copy_participatory_process_components
      new_component_id = nil
      @participatory_process.components.each do |component|
        copied_step_settings = @form.copy_steps? ? map_step_settings(component.step_settings) : {}
        new_component = Decidim::Component.create!(
          manifest_name: component.manifest_name,
          name: component.name,
          participatory_space: @copied_process,
          settings: component.settings,
          step_settings: copied_step_settings,
          weight: component.weight
        )
        new_component_id = new_component.id if new_component.manifest_name == "proposals"
        component.manifest.run_hooks(:copy, new_component:, old_component: component)
      end
      component_id = @participatory_process.components.where(manifest_name: "proposals")&.first&.id
      proposal_states = Decidim::Proposals::ProposalState.where(decidim_component_id: component_id) if component_id
      copy_proposal_states(proposal_states, new_component_id) if proposal_states
    end

    def copy_proposal_states(states, new_component_id)
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

Decidim::ParticipatoryProcesses::Admin::DuplicateParticipatoryProcess.include(DuplicateParticipatoryProcessExtends)
