# frozen_string_literal: true

module Decidim
  module Ai
    class SpamDigestJob < ApplicationJob
      queue_as :mailers

      def perform(time: Time.now.utc, force: false)
        # Cible les admins
        Decidim::User.where(admin: true).find_each do |user|
          # 2️⃣ Vérifie si cet utilisateur doit recevoir un digest
          should_notify = force || Decidim::NotificationsDigestSendingDecider.must_notify?(user, time)
          next unless should_notify

          # Sélectionne uniquement les notifications de spam IA
          notification_ids = Decidim::Notification
                               .where(event_class: "Decidim::Ai::SpamReportCreatedEvent")
                               .where(decidim_user_id: user.id)
                               .where("created_at >= ?", time - 1.week)
                               .pluck(:id)

          next if notification_ids.blank?

          # Envoie l’email digest avec mailer AI
          Decidim::Ai::SpamDigestMailer.digest_mail(user, notification_ids).deliver_later

          # Met à jour le timestamp
          user.update!(digest_sent_at: time)
        end
      end
    end
  end
end
