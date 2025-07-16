# frozen_string_literal: true

require "active_support/concern"
module UpdateQuestionnaireExtends
  extend ActiveSupport::Concern

  included do
    def update_display_conditions(form_question, question)
      # Remove all existing conditions for this question to avoid association issues
      question.display_conditions.destroy_all

      # Recreate conditions from form data
      form_question.display_conditions.each do |form_display_condition|
        # Skip conditions marked for deletion
        next if form_display_condition.deleted?

        type = form_display_condition.condition_type

        display_condition_attributes = {
          condition_question: form_display_condition.condition_question,
          condition_type: form_display_condition.condition_type,
          condition_value: type == "match" ? form_display_condition.condition_value : nil,
          answer_option: %w(equal not_equal).include?(type) ? form_display_condition.answer_option : nil,
          mandatory: form_display_condition.mandatory
        }

        # Create new condition and associate it explicitly to the correct question to avoid that
        # it goes to the question the condition was about
        new_condition = question.display_conditions.build(display_condition_attributes)
        new_condition.save!
      end
    end

    def update_questionnaire_question(form_question)
      question_attributes = {
        body: form_question.body,
        description: form_question.description,
        position: form_question.position,
        mandatory: form_question.mandatory,
        question_type: form_question.question_type,
        max_choices: form_question.max_choices,
        max_characters: form_question.max_characters
      }

      update_nested_model(form_question, question_attributes, @questionnaire.questions) do |question|
        form_question.answer_options.each do |form_answer_option|
          answer_option_attributes = {
            body: form_answer_option.body,
            free_text: form_answer_option.free_text
          }

          update_nested_model(form_answer_option, answer_option_attributes, question.answer_options)
        end

        # FIX: Collect IDs of display_conditions to preserve
        form_display_condition_ids = form_question.display_conditions
                                                  .reject { |dc| dc.deleted? && dc.id.blank? }
                                                  .map(&:id)
                                                  .compact

        # FIX: Remove display_conditions no longer present in form
        question.display_conditions.where.not(id: form_display_condition_ids).destroy_all if form_display_condition_ids.any?

        # FIX: Updated display_conditions handling
        update_display_conditions(form_question, question)

        form_question.matrix_rows_by_position.each_with_index do |form_matrix_row, idx|
          matrix_row_attributes = {
            body: form_matrix_row.body,
            position: form_matrix_row.position || idx
          }

          update_nested_model(form_matrix_row, matrix_row_attributes, question.matrix_rows)
        end
      end
    end
  end
end

Decidim::Forms::Admin::UpdateQuestionnaire.include(UpdateQuestionnaireExtends)
