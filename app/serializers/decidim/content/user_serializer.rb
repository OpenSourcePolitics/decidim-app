# frozen_string_literal: true

module Decidim
  module Content
    class UserSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          type: resource.type,
          blocked: resource.blocked,
          email: resource.email,
          name: resource.name,
          nickname: resource.nickname,
          locale: resource.locale,
          admin: resource.admin,
          roles: resource.roles,
          personal_url: resource.personal_url,
          about: resource.about,
          avatar: blob_url(resource.avatar, resource.organization),
          extended_data: serialize_extended_data,
          notification_settings: resource.notification_settings,
          direct_message_types: resource.direct_message_types,
          created_at: resource.created_at,
          updated_at: resource.updated_at,
          confirmed_at: resource.confirmed_at,
          unconfirmed_email: resource.unconfirmed_email,
          deleted_at: resource.deleted_at,
          delete_reason: resource.delete_reason
        }
      end

      def serialize_extended_data
        data = resource.extended_data || {}
        data["phone_number"] = format_phone_number(resource.phone_number, resource.phone_country) if resource.phone_number.present?
        data
      end

      private

      def format_phone_number(phone_number, phone_country)
        prefix = "+#{ISO3166::Country.find_country_by_alpha2(phone_country)&.country_code}" if phone_country.present?
        "#{prefix}#{phone_number}"
      end
    end
  end
end
