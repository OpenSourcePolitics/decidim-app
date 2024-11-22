# frozen_string_literal: true

module UserAnswersSerializerExtends
  extend ActiveSupport::Concern

  included do
    private

    def hash_for(answer)
      {
        answer_translated_attribute_name(:id) => answer&.session_token,
        answer_translated_attribute_name(:created_at) => answer&.created_at&.to_s(:db),
        answer_translated_attribute_name(:ip_hash) => answer&.ip_hash,
        answer_translated_attribute_name(:user_status) => answer_translated_attribute_name(answer&.decidim_user_id.present? ? "registered" : "unregistered")
      }.merge(user_data(answer))
    end

    def user_data(answer)
      {
        answer_translated_attribute_name(:email) => answer&.user&.email.presence || "",
        answer_translated_attribute_name(:name) => answer&.user&.name || ""
      }
    end

    def answer_translated_attribute_name(attribute)
      I18n.t(attribute.to_sym, scope: "decidim.forms.user_answers_serializer", default: attribute.to_s)
    end
  end
end

Decidim::Forms::UserAnswersSerializer.class_eval do
  include(UserAnswersSerializerExtends)
end
