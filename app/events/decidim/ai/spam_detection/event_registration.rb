# frozen_string_literal: true

Decidim::Events.register!(
  "decidim.events.ai.spam_detection.spam_digest_event",
  {
    event_class: "Decidim::Ai::SpamDetection::SpamDigestEvent",
    resource_type: "Decidim::Organization",
    notify_followers: true
  }
)
