# frozen_string_literal: true

module AnswerQuestionnaireExtends
  extend ActiveSupport::Concern

  included do
    def answer_questionnaire
      @main_form = @form
      @errors = nil

      Decidim::Forms::Answer.transaction(requires_new: true) do
        form.responses_by_step.flatten.select(&:display_conditions_fulfilled?).each do |form_answer|
          answer = Decidim::Forms::Answer.find_or_initialize_by(
            user: current_user,
            questionnaire: @questionnaire,
            question: form_answer.question,
            session_token: form.context.session_token
          )
          answer.body = form_answer.body
          answer.ip_hash = form.context.ip_hash
          answer.choices.destroy_all if answer.persisted?

          build_choices(answer, form_answer)

          answer.save!

          next unless form_answer.question.has_attachments?

          @form = form_answer
          @attached_to = answer

          build_attachments

          if attachments_invalid?
            @errors = true
            next
          end

          create_attachments if process_attachments?
          document_cleanup!
        end

        @form = @main_form
        raise ActiveRecord::Rollback if @errors
      end
    end
  end
end

Decidim::Forms::AnswerQuestionnaire.include(AnswerQuestionnaireExtends)
