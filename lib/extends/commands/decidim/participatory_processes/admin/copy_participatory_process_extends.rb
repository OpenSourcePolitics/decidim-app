# frozen_string_literal: true

require "active_support/concern"
module CopyParticipatoryProcessExtends
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
  end
end

Decidim::ParticipatoryProcesses::Admin::CopyParticipatoryProcess.include(CopyParticipatoryProcessExtends)
