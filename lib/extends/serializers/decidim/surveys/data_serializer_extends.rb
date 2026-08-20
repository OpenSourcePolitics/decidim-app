# frozen_string_literal: true

module SurveysDataSerializerExtends
  extend ActiveSupport::Concern

  included do
    def serialize_questions(questions)
      questions.collect do |question|
        json = question.attributes.as_json
        json[:matrix_rows] = serialize_matrix_rows(question.matrix_rows)
        json[:answer_options] = serialize_answer_options(question.answer_options)
        json
      end
    end

    def serialize_matrix_rows(matrix_rows)
      matrix_rows.collect do |row|
        row.attributes.as_json
      end
    end
  end
end

Decidim::Surveys::DataSerializer.class_eval do
  include(SurveysDataSerializerExtends)
end
