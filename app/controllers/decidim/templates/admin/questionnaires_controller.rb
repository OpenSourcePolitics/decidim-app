# frozen_string_literal: true

module Decidim
  module Templates
    module Admin
      # This controller is added to match the route "/questionnaire_template/questionnaire/answer_options(.:format)" in decidim-templates
      # TO DO : delete it when the correction on route is integrated
      class QuestionnairesController < Admin::ApplicationController
        include Decidim::Forms::Admin::Concerns::HasQuestionnaire

        def answer_options
          respond_to do |format|
            format.json do
              question_id = params["id"]
              question = Decidim::Forms::Question.find_by(id: question_id)
              render json: question.answer_options.map { |answer_option| Decidim::Forms::AnswerOptionPresenter.new(answer_option).as_json } if question.present?
            end
          end
        end
      end
    end
  end
end
