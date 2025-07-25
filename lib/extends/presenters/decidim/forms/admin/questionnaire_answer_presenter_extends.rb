# frozen_string_literal: true

module QuestionnaireAnswerPresenterExtends
  extend ActiveSupport::Concern

  included do
    def pretty_attachment(attachment)
      # rubocop:disable Style/StringConcatenation
      # Interpolating strings that are `html_safe` is problematic with Rails.
      content_tag :li do
        link_to(attachment_url(attachment), target: "_blank", rel: "noopener noreferrer") do
          content_tag(:span) do
            translated_attribute(attachment.title).presence ||
              I18n.t("download_attachment", scope: "decidim.forms.questionnaire_answer_presenter")
          end + " " + content_tag(:small) do
            "#{attachment.file_type} #{number_to_human_size(attachment.file_size)}"
          end
        end
      end
      # rubocop:enable Style/StringConcatenation
    end

    private

    # Return the URL of the attachment, depending on its type.
    # It should be a file, but we also support ActiveStorage blobs and other types.
    def attachment_url(attachment)
      if attachment.is_a?(ActiveStorage::Blob)
        Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
      elsif attachment.respond_to?(:file) && attachment.file.attached?
        Rails.application.routes.url_helpers.rails_blob_url(attachment.file.blob, only_path: true)
      elsif attachment.respond_to?(:url)
        attachment.url
      else
        "#"
      end
    end
  end
end

Decidim::Forms::Admin::QuestionnaireAnswerPresenter.class_eval do
  include(QuestionnaireAnswerPresenterExtends)
end
