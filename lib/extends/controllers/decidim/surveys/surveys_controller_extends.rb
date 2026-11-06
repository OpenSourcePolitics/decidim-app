# frozen_string_literal: true

module SurveysControllerExtends
  extend ActiveSupport::Concern

  included do
    def visitor_already_answered?
      questionnaire.answered_by?(current_user || session_token)
    end

    def session_token
      return nil unless current_user || request&.session

      @session_token ||= tokenize(current_user&.id || request.session.id.to_s)
    end
  end
end

Decidim::Surveys::SurveysController.include(SurveysControllerExtends)
