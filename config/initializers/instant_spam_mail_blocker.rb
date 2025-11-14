# frozen_string_literal: true

# Patch to stop instant spam report emails from Decidim-AI when frequency is daily, weekly
# Allows the Spam Summary Digest to manage notifications (daily, weekly)
# instead of non-configurable real-time emails from Decidim-ai report

module Decidim
  module InstantSpamMailBlocker
    def send_report_notification_to_moderators
      return if spam_report? && !frequency_notifications_is_realtime?(@report.moderation.participatory_space.organization.admins)

      super
    end

    def send_notification_to_admins!
      return if spam_report? && !frequency_notifications_is_realtime?(@report.moderation.user.organization.admins)

      super
    end

    private

    def spam_report?
      @report.reason.to_s == "spam"
    end

    def frequency_notifications_is_realtime?(admins)
      admins.any? { |a| a.notifications_sending_frequency == "realtime" }
    end
  end
end

Rails.application.config.to_prepare do
  Decidim::CreateReport.prepend(Decidim::InstantSpamMailBlocker)
  Decidim::CreateUserReport.prepend(Decidim::InstantSpamMailBlocker)
end
