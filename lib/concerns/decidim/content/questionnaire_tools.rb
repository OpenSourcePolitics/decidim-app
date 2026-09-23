# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module QuestionnaireTools
      extend ActiveSupport::Concern
      included do
        def convert_questionnaire_json_to_uid(questionnaire_json, module_prefix: "Decidim::Forms")
          return if questionnaire_json.blank?

          questionnaire_json.tap do |json|
            questionnaire_uid = uid("#{module_prefix}::Questionnaire".constantize.new(id: json["id"].to_i))
            questionnaire_for_uid = uid(
              json["questionnaire_for_type"].safe_constantize&.new(
                id: json["questionnaire_for_id"].to_i
              )
            )

            json["id"] = questionnaire_uid
            json["questionnaire_for"] = questionnaire_for_uid
            json["questions"]&.each do |question|
              question["id"] = uid("#{module_prefix}::Question".constantize.new(id: question["id"].to_i))
              question["decidim_questionnaire_id"] = json["id"]
              question["answer_options"]&.each do |answer_option|
                answer_option["id"] = uid("#{module_prefix}::AnswerOption".constantize.new(id: answer_option["id"].to_i))
                answer_option["decidim_question_id"] = question["id"]
              end
              question["matrix_rows"]&.each do |matrix_row|
                matrix_row["id"] = uid("#{module_prefix}::QuestionMatrixRow".constantize.new(id: matrix_row["id"].to_i))
                matrix_row["decidim_question_id"] = question["id"]
              end
            end
          end
        end

        def serialize_questionnaire(questionnaire)
          return if questionnaire_is_pristine?(questionnaire)

          questionnaire.attributes.as_json.tap do |json|
            json[:questions] = serialize_questions(questionnaire.questions.order(:position))
          end
        end

        def serialize_questions(questions)
          questions.collect do |question|
            json = question.attributes.as_json
            json[:answer_options] = serialize_answer_options(question.answer_options)
            json
          end
        end

        def serialize_answer_options(answer_options)
          answer_options.collect do |option|
            option.attributes.as_json
          end
        end

        def questionnaire_is_pristine?(questionnaire)
          questionnaire.blank? || (questionnaire.created_at.to_i == questionnaire.updated_at.to_i && questionnaire.questions.empty?)
        end
      end
    end
  end
end
