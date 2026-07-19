# frozen_string_literal: true

module Decidim
  module Content
    class MeetingSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          author: uid(identity(resource)),
          category: uid(resource.try(:category)),
          scope: uid(resource.try(:scope)),
          title: normalize_translated_attribute(resource.try(:title)),
          description: normalize_translated_attribute(resource.try(:description)),
          start_time: resource.try(:start_time),
          end_time: resource.try(:end_time),
          type_of_meeting: resource.try(:type_of_meeting),
          online_meeting_url: resource.try(:online_meeting_url),
          video_url: resource.try(:video_url),
          audio_url: resource.try(:audio_url),
          address: resource.try(:address),
          latitude: resource.try(:latitude),
          longitude: resource.try(:longitude),
          location: resource.try(:location),
          location_hints: resource.try(:location_hints),
          private_meeting: resource.try(:private_meeting),
          transparent: resource.try(:transparent),
          agenda: serialize_agenda,
          services: serialize_services,
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          published_at: resource.try(:published_at),
          withdrawn: resource.withdrawn?,
          withdrawn_at: resource.try(:withdrawn_at),
          registrations_enabled: resource.try(:registrations_enabled),
          available_slots: resource.try(:available_slots),
          reserved_slots: resource.try(:reserved_slots),
          registration_terms: normalize_translated_attribute(resource.try(:registration_terms)),
          registration_type: resource.try(:registration_type),
          # enable_registration_confirmation: resource.try(:enable_registration_confirmation),
          # enable_cancellation: resource.try(:enable_cancellation),
          # disable_account_confirmation: resource.try(:disable_account_confirmation),
          customize_registration_email: resource.try(:customize_registration_email),
          registration_email_custom_content: normalize_translated_attribute(resource.try(:registration_email_custom_content)),
          salt: resource.try(:salt),
          registration_url: resource.try(:registration_url),
          registration_form_enabled: resource.try(:registration_form_enabled),
          registration_form: convert_questionnaire_json_to_uid(serialize_questionnaire(resource.try(:questionnaire))),
          attendees_count: resource.try(:attendees_count),
          contributions_count: resource.try(:contributions_count),
          attending_organizations: resource.try(:attending_organizations),
          poll: convert_questionnaire_json_to_uid(serialize_questionnaire(resource.try(:poll)&.questionnaire), module_prefix: "Decidim::Meetings"),
          comments_enabled: resource.try(:comments_enabled),
          comments_count: resource.try(:comments_count),
          comments_start_time: resource.try(:comments_start_time),
          comments_end_time: resource.try(:comments_end_time),
          followers_count: resource.try(:follows).try(:size),
          related_proposals: resource.linked_resources(:proposals, "proposals_from_meeting").map { |proposal| uid(proposal) },
          related_results: resource.linked_resources(:results, "meetings_through_proposals").map { |result| uid(result) },
          closing_visible: resource.try(:closing_visible),
          closing_report: normalize_translated_attribute(resource.try(:closing_report)),
          component: uid(resource.try(:component)),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        }
      end

      def serialize_agenda
        return if (agenda = resource.try(:agenda)).blank?

        {
          uid: uid(agenda),
          title: normalize_translated_attribute(agenda.try(:title)),
          description: normalize_translated_attribute(agenda.try(:description)),
          duration: agenda.try(:duration),
          items: agenda.agenda_items.first_class.map do |item|
            {
              uid: uid(item),
              title: normalize_translated_attribute(item.try(:title)),
              description: normalize_translated_attribute(item.try(:description)),
              duration: item.try(:duration),
              items: item.agenda_item_children.map do |child_item|
                {
                  uid: uid(child_item),
                  title: normalize_translated_attribute(child_item.try(:title)),
                  description: normalize_translated_attribute(child_item.try(:description)),
                  duration: child_item.try(:duration)
                }
              end
            }
          end
        }
      end

      def serialize_services
        return if (services = resource.try(:services)).blank?

        services.map do |service|
          {
            uid: uid(service),
            title: normalize_translated_attribute(service.try(:title)),
            description: normalize_translated_attribute(service.try(:description))
          }
        end
      end
    end
  end
end
