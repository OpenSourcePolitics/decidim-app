# frozen_string_literal: true

require "active_support/concern"
module CopyAssemblyExtends
  extend ActiveSupport::Concern

  included do
    def call
      return broadcast(:invalid) if form.invalid?

      Decidim.traceability.perform_action!("duplicate", @assembly, @user) do
        Decidim::Assembly.transaction do
          copy_assembly
          copy_assembly_attachments
          copy_assembly_categories if @form.copy_categories?
          copy_assembly_components if @form.copy_components?
          copy_landing_page_blocks if @form.copy_landing_page_blocks?
        end
      end

      broadcast(:ok, @copied_assembly)
    end


    private

    def copy_landing_page_blocks
      blocks = Decidim::ContentBlock.where(scoped_resource_id: @assembly.id, scope_name: "assembly_homepage", organization: @assembly.organization)
      if blocks.present?
        blocks.each do |block|
          new_block = Decidim::ContentBlock.create!(
            organization: @copied_assembly.organization,
            scope_name: "assembly_homepage",
            scoped_resource_id: @copied_assembly.id,
            manifest_name: block.manifest_name,
            settings: block.settings,
            weight: block.weight,
            published_at: block.published_at.present? ? @copied_assembly.created_at : nil, # determine if block is active/inactive
            )
          copy_block_attachments(block, new_block) if block.attachments.present?
        end
      end
    end

    def copy_block_attachments(block, new_block)
      block.attachments.map(&:name).each do |name|
        original_image = block.images_container.send(name).blob.download
        new_block.images_container.send("#{name}=", ActiveStorage::Blob.create_and_upload!(
                                                      io: StringIO.new(original_image),
                                                      filename: "image.png",
                                                      content_type: block.images_container.background_image.blob.content_type
                                                    ))
        new_block.save!
      end
    end
  end
end

Decidim::Assemblies::Admin::CopyAssembly.include(CopyAssemblyExtends)
