# frozen_string_literal: true

module Decidim
  module Content
    class MeetingInviteSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          user: uid(Decidim::User.new(id: resource.try(:decidim_user_id))),
          meeting: uid(Decidim::Meetings::Meeting.new(id: resource.try(:decidim_meeting_id))),
          sent_at: resource.sent_at,
          accepted_at: resource.accepted_at,
          rejected_at: resource.rejected_at
        }
      end
    end
  end
end
