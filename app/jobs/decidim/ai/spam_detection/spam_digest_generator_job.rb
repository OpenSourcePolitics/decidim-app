# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      class SpamDigestGeneratorJob < ApplicationJob
        queue_as :mailers

        def perform(frequency)
          Decidim::Organization.find_each do |organization|
            admins = organization.admins.where(notifications_sending_frequency: frequency)
            next if admins.empty?

            spam_count = count_spam(organization, frequency)
            next if spam_count.zero?

            Rails.logger.info "[Decidim-AI] Organization '#{organization.name}' → #{spam_count} spams détectés (#{frequency})"

            Decidim::EventsManager.publish(
              event: "decidim.events.ai.spam_detection.spam_digest_event",
              event_class: Decidim::Ai::SpamDetection::SpamDigestEvent,
              resource: organization,
              followers: admins,
              extra: { spam_count:, frequency: frequency }
            )
          end
        end

        private

        def count_spam(organization, frequency)
          since = frequency == :weekly ? 1.week.ago : 1.day.ago

          Decidim::Report
            .joins("INNER JOIN decidim_moderations ON decidim_reports.decidim_moderation_id = decidim_moderations.id")
            .joins("INNER JOIN decidim_participatory_processes ON decidim_moderations.decidim_participatory_space_id = decidim_participatory_processes.id AND decidim_moderations.decidim_participatory_space_type = 'Decidim::ParticipatoryProcess'")
            .where("decidim_participatory_processes.decidim_organization_id = ?", organization.id)
            .where(reason: "spam")
            .where("decidim_reports.created_at >= ?", since)
            .count
        end
      end
    end
  end
end
