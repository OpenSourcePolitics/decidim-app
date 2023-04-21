# frozen_string_literal: true

require "active_support/concern"
module EditorImagesExtends
  extend ActiveSupport::Concern
  included do
    def create
      enforce_permission_to :create, :editor_image

      @form = form(Decidim::EditorImageForm).from_params(form_values)

      Decidim::CreateEditorImage.call(@form) do
        on(:ok) do |image|
          render json: { url: image.attached_uploader(:file).url(host: organization_host), message: I18n.t("success", scope: "decidim.editor_images.create") }
        end

        on(:invalid) do |_message|
          render json: { message: I18n.t("error", scope: "decidim.editor_images.create") }, status: :unprocessable_entity
        end
      end
    end

    private

    def organization_host
      return current_organization.host unless Rails.env.development?

      "#{request.host}:#{request.port}"
    end
  end
end

Decidim::EditorImagesController.include(EditorImagesExtends)
