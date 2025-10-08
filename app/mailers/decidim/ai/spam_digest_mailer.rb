# frozen_string_literal: true

module Decidim
  module Ai
    class SpamDigestMailer < Decidim::ApplicationMailer

      def digest_mail(user, notification_ids)
        with_user(user) do
          notifications = Decidim::Notification.where(id: notification_ids)
          @user = user
          @organization = user.organization
          @notifications_digest = Decidim::NotificationsDigestPresenter.new(user)
          @notifications = notifications

          mail(to: user.email, subject: "AI Spam Summary")
        end
      end
    end
  end
end


