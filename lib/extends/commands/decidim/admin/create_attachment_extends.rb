# frozen_string_literal: true

require "active_support/concern"

module CreateAttachmentExtends
  extend ActiveSupport::Concern

  included do
    def notify_followers
      return unless @attachment.attached_to.is_a?(Decidim::Followable)
      return unless form.send_notification_to_followers

      Decidim::EventsManager.publish(
        event: "decidim.events.attachments.attachment_created",
        event_class: Decidim::AttachmentCreatedEvent,
        resource: @attachment,
        followers: @attachment.attached_to.followers,
        extra: { force_email: true },
        force_send: true
      )
    end
  end
end

Decidim::Admin::CreateAttachment.include(CreateAttachmentExtends)
