# frozen_string_literal: true

module Decidim
  module NotificationsDigest
    def self.notifications_digest(frequency)
      return unless [:daily, :weekly].include?(frequency)

      time = Time.now.utc
      Decidim::User.where(notifications_sending_frequency: frequency).find_each do |user|
        Decidim::EmailNotificationsDigestGeneratorJob.perform_later(user.id, frequency, time: time)
      end
    end
  end
end
