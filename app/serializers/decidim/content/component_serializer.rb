# frozen_string_literal: true

module Decidim
  module Content
    class ComponentSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          manifest_name: resource.manifest_name,
          name: normalize_translated_attribute(resource.name),
          settings: convert_settings_to_uid(resource[:settings]),
          weight: resource.try(:weight),
          permissions: resource.try(:permissions),
          published_at: resource.try(:published_at),
          previously_published: resource.try(:previously_published?),
          specific_data: convert_specific_data_to_uid(resource.manifest.specific_data_serializer_class&.new(resource)&.run),
          participatory_space: polymorphic_uid(resource, :participatory_space),
          url: Decidim::EngineRouter.main_proxy(resource)&.root_url
        }
      end

      def convert_settings_to_uid(settings)
        return unless settings

        settings.tap do |s|
          s["steps"].transform_keys! { |key| uid(Decidim::ParticipatoryProcessStep.new(id: key.to_i)) } if s["steps"].present?
          s["global"]["scope_id"] = uid(Decidim::Scope.new(id: s["global"]["scope_id"].to_i)) if s.dig("global", "scope_id").present?
        end
      end

      def convert_specific_data_to_uid(specific_data)
        return unless specific_data
        return specific_data.map { |data| convert_specific_data_to_uid(data) } if specific_data.is_a?(Array)

        if specific_data.is_a?(Hash) && resource.manifest_name == "surveys"
          convert_surveys_specific_data_to_uid(specific_data)
        else
          specific_data
        end
      end

      def convert_surveys_specific_data_to_uid(specific_data)
        return unless specific_data

        # TODO: duplicated data (like id references) should be removed

        specific_data["id"] = uid(Decidim::Surveys::Survey.new(id: specific_data["id"].to_i))
        specific_data["decidim_component_id"] = uid(resource)

        return unless specific_data["questionnaire"]

        specific_data["questionnaire"]["id"] = uid(Decidim::Forms::Questionnaire.new(id: specific_data["questionnaire"]["id"].to_i))
        specific_data["questionnaire"]["questionnaire_for"] = specific_data["id"]
        specific_data["questionnaire"]["questions"]&.each do |question|
          question["id"] = uid(Decidim::Forms::Question.new(id: question["id"].to_i))
          question["decidim_questionnaire_id"] = specific_data["questionnaire"]["id"]
          question["answer_options"]&.each do |answer_option|
            answer_option["id"] = uid(Decidim::Forms::AnswerOption.new(id: answer_option["id"].to_i))
            answer_option["decidim_question_id"] = question["id"]
          end
          question["matrix_rows"]&.each do |matrix_row|
            matrix_row["id"] = uid(Decidim::Forms::QuestionMatrixRow.new(id: matrix_row["id"].to_i))
            matrix_row["decidim_question_id"] = question["id"]
          end
        end
        specific_data
      end
    end
  end
end
