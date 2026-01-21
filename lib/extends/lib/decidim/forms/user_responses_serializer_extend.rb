# frozen_string_literal: true

module UserResponsesSerializerExtends
  extend ActiveSupport::Concern

  included do
    private

    def hash_for(response)
      {
        response_translated_attribute_name(:id) => response&.session_token,
        response_translated_attribute_name(:created_at) => response&.created_at&.to_fs(:db),
        response_translated_attribute_name(:ip_hash) => response&.ip_hash,
        response_translated_attribute_name(:user_status) => response_translated_attribute_name(response&.decidim_user_id.present? ? "registered" : "unregistered")
      }.merge(user_data(response))
    end

    def user_data(response)
      {
        response_translated_attribute_name(:email) => response&.user&.email.presence || "",
        response_translated_attribute_name(:name) => response&.user&.name || ""
      }
    end

    def response_translated_attribute_name(attribute)
      I18n.t(attribute.to_sym, scope: "decidim.forms.user_responses_serializer", default: attribute.to_s)
    end
  end
end

Decidim::Forms::UserResponsesSerializer.class_eval do
  include(UserResponsesSerializerExtends)
end
