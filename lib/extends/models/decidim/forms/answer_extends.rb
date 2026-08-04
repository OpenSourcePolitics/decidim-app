# frozen_string_literal: true

module AnswerExtends
  extend ActiveSupport::Concern

  included do
    validates :decidim_question_id, uniqueness: {
      scope: [:decidim_questionnaire_id, :session_token, :decidim_user_id],
      message: ->(_object, _data) { I18n.t("decidim.forms.answer.errors.duplicate") }
    }
  end
end

Decidim::Forms::Answer.include(AnswerExtends)
