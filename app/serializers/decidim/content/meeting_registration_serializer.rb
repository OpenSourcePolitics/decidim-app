# frozen_string_literal: true

module Decidim
  module Content
    class MeetingRegistrationSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          user: uid(Decidim::User.new(id: resource.try(:decidim_user_id))),
          user_group: uid(Decidim::UserGroup.new(id: resource.try(:decidim_user_group_id))),
          meeting: uid(Decidim::Meetings::Meeting.new(id: resource.try(:decidim_meeting_id))),
          code: resource.try(:code),
          validated_at: resource.try(:validated_at),
          public_participation: resource.try(:public_participation),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at)
        }
      end
    end
  end
end
