# frozen_string_literal: true

module Decidim
  module Content
    class MeetingPollAnswersSerializer < Decidim::Content::BaseContentSerializer
      def initialize(answers)
        @answers = answers
      end

      attr_reader :answers
      alias resource answers

      def serialize
        {
          **user_data,
          questionnaire_id: answers&.first&.decidim_questionnaire_id,
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

        questions = Decidim::Meetings::Question.where(decidim_questionnaire_id: questionnaire_id).order(:position)
        return {} if questions.none?

        answers_hash = answers.each.inject({}) do |result, answer|
          result.update(
            answer.question.id => answer
          )
        end

        questions.each.inject({}) do |serialized, question|
          serialized.update(
            uid(question) => normalize_body(answers_hash[question.id])
          )
        end
      end

      def normalize_body(answer)
        normalize_choices(answer&.choices)
      end

      def normalize_choices(choices)
        choices&.order(:position)&.map { |choice| normalize_single_choice(choice) }
      end

      def normalize_single_choice(choice)
        {
          answer_option: uid(Decidim::Meetings::AnswerOption.new(id: choice.decidim_answer_option_id)),
          position: choice.try(:position),
          body: choice.try(:body),
          custom_body: choice.try(:custom_body)
        }
      end
    end
  end
end
