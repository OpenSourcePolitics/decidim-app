# frozen_string_literal: true

module EditorImagesExtends
  def create
    enforce_permission_to :create, :editor_image

    @form = form(Decidim::EditorImageForm).from_params(form_values)

    Decidim::CreateEditorImage.call(@form) do
      on(:ok) do |image|
        render json: { url: image.attached_uploader(:file).url(host: current_organization.host), message: I18n.t("success", scope: "decidim.editor_images.create") }
      end

      on(:invalid) do |_message|
        render json: { message: I18n.t("error", scope: "decidim.editor_images.create") }, status: :unprocessable_entity
      end
    end
  end
end

Decidim::EditorImagesController.class_eval do
  prepend(EditorImagesExtends)
end
