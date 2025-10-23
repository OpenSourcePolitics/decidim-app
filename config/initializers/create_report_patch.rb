# frozen_string_literal:true

# Patch to stop instant spam report emails from Decidim-AI.
# Allows the Spam Summary Digest to manage notifications (daily, weekly, or none) instead of non-configurable real-time emails.

module Decidim
 module CreateReportNoSpamMail
  def send_report_notification_to_moderators
   return if @report.reason.to_s == "spam"
   super
  end
 end
end

Rails.application.config.to_prepare do
 Decidim::CreateReport.prepend(Decidim::CreateReportNoSpamMail)
end
