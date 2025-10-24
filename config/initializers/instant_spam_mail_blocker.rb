# frozen_string_literal: true

# Patch to stop instant spam report emails from Decidim-AI.
# Allows the Spam Summary Digest to manage notifications (daily, weekly, or none)
# instead of non-configurable real-time emails from Decidim-ai report

module Decidim
  module InstantSpamMailBlocker
    def send_report_notification_to_moderators
      return if @report.reason.to_s == "spam"

      Rails.logger.info("[Decidim-AI] 🧩 Skipped spam mail for moderator report ID=#{@report.id}")
      super
    end

    def send_notification_to_admins!
      return if @report.reason.to_s == "spam"

      Rails.logger.info("[Decidim-AI] send_notification_to_admins! USER Skipped spam mail for moderator report ID=#{@report.id}")
      super
    end
  end
end

Rails.application.config.to_prepare do
  Decidim::CreateReport.prepend(Decidim::InstantSpamMailBlocker)
  Decidim::CreateUserReport.prepend(Decidim::InstantSpamMailBlocker)
end
