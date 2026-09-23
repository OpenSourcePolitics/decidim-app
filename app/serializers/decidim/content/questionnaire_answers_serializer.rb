# frozen_string_literal: true

module Decidim
  module Content
    class QuestionnaireAnswersSerializer < Decidim::Content::BaseContentSerializer
      EXCLUDED_QUESTION_TYPES = [
        Decidim::Forms::Question::SEPARATOR_TYPE,
        Decidim::Forms::Question::TITLE_AND_DESCRIPTION_TYPE
      ].freeze

      def initialize(answers, **options)
        @answers = answers
        @options = options
      end

      attr_reader :answers
      alias resource answers

      def serialize
        {
          **user_data,
          created_at: answers&.first&.created_at,
          **questions_hash
        }
      end

      def user_data
        if answers&.first&.decidim_user_id.present?
          {
            author: uid(Decidim::User.new(id: answers&.first&.decidim_user_id)),
            author_status: "registered"
          }
        else
          {
            author: nil,
            author_status: "unregistered"
          }
        end
      end

      def questions_hash
        questionnaire_id = answers&.first&.decidim_questionnaire_id
        return {} unless questionnaire_id

        questions = Decidim::Forms::Question.where(decidim_questionnaire_id: questionnaire_id).where.not(question_type: EXCLUDED_QUESTION_TYPES).order(:position)
        return {} if questions.none?

        answers_hash = answers.each.inject({}) do |result, answer|
          result.update(
            answer.question.id => answer
          )
        end

        questions.each.inject({}) do |serialized, question|
          serialized.update(
            uid(question) => normalize_body(question, answers_hash[question.id])
          )
        end
      end

      def normalize_body(question, answer)
        case question.question_type
        when "single_option", "multiple_option", "sorting"
          normalize_choices(answer&.choices)
        when "matrix_single", "matrix_multiple"
          normalize_matrix(question, answer)
        when "files"
          answer&.attachments&.map(&:url)
        else
          answer&.try(:body)
        end
      end

      def normalize_matrix(question, answer)
        question.matrix_rows&.map do |matrix_row|
          {
            uid(matrix_row) => normalize_choices(answer&.choices&.where(matrix_row:))
          }
        end
      end

      def normalize_choices(choices)
        choices&.order(:position)&.map { |choice| normalize_single_choice(choice) }
      end

      def normalize_single_choice(choice)
        {
          answer_option: uid(Decidim::Forms::AnswerOption.new(id: choice.decidim_answer_option_id)),
          position: choice.try(:position),
          body: choice.try(:body),
          custom_body: choice.try(:custom_body)
        }
      end
    end
  end
end
