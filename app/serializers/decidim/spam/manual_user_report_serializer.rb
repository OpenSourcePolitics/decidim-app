# frozen_string_literal: true

module Decidim
  module Spam
    class ManualUserReportSerializer < Decidim::Exporters::Serializer
      def serialize
        {
          id: resource.id,
          nickname: resource.nickname,
          name: resource.name,
          email: resource.email,
          personal_url: resource.personal_url,
          about: resource.about&.truncate(80)&.squish,
          avatar_attached: resource.avatar.attached?,
          created_at: resource.created_at,
          updated_at: resource.updated_at,
          sign_in_count: resource.sign_in_count,
          last_sign_in_at: resource.last_sign_in_at,
          spam: resource.extended_data.dig("spam_detection", "manual") || {},
          force_spam_conclusion: nil,
          force_user_block: nil,
          force_justification: nil
        }
      end
    end
  end
end
