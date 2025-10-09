# frozen_string_literal: true

Decidim::EmailNotificationsDigestGeneratorJob.class_eval do
  alias_method :original_perform, :perform

  def perform(user_id, frequency, time: Time.now.utc, force: false)
    user = Decidim::User.find_by(id: user_id)
    return if user.blank?

    # 1️⃣ Comportement d’origine : digest Decidim normal
    original_perform(user_id, frequency, time:, force:)

    # 2️⃣ Notre ajout : digest IA
    notification_ids = Decidim::Notification
                         .where(event_class: "Decidim::Ai::SpamReportCreatedEvent")
                         .where(decidim_user_id: user.id)
                         .where("created_at >= ?", time - 1.week)
                         .pluck(:id)

    return if notification_ids.blank?

    Decidim::Ai::SpamDigestMailer.digest_mail(user, notification_ids).deliver_later
  end
end

