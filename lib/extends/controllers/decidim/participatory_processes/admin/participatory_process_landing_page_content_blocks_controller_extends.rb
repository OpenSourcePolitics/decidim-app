# frozen_string_literal: true

require "active_support/concern"

module ParticipatoryProcessLandingPageContentBlocksControllerExtends
  extend ActiveSupport::Concern

  included do
    def update
      enforce_permission_to_update_resource

      @form = form(Decidim::Admin::ContentBlockForm).from_params(params)

      Decidim::Admin::ContentBlocks::UpdateContentBlock.call(@form, content_block, content_block_scope) do
        on(:ok) do
          redirect_to edit_resource_landing_page_path
        end
        on(:invalid) do
          flash.now[:error] = content_block.errors.full_messages.join(", ").presence || t("decidim.admin.content_blocks.update.error", default: "Erreur lors de la mise à jour")
          render "decidim/admin/shared/landing_page_content_blocks/edit"
        end
      end
    end
  end
end

Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessLandingPageContentBlocksController.include(ParticipatoryProcessLandingPageContentBlocksControllerExtends)
