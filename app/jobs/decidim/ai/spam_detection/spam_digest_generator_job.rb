# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      class SpamDigestGeneratorJob < ApplicationJob
        queue_as :mailers

        def perform(frequency)
          Decidim::Organization.find_each do |organization|
            Rails.logger.info("[Decidim-AI] Running spam digest (#{frequency}) for #{organization.name}")

            admins = organization.admins.where(notifications_sending_frequency: frequency)
            next if admins.empty?

            spam_count = count_spam(organization, frequency)
            next if spam_count.zero?

            Rails.logger.info "[Decidim-AI] Organization '#{organization.name}' → #{spam_count} spams détectés (#{frequency})"

            Decidim::EventsManager.publish(
              event: "decidim.events.ai.spam_detection.spam_digest_event",
              event_class: Decidim::Ai::SpamDetection::SpamDigestEvent,
              resource: organization,
              followers: organization.admins.where(notifications_sending_frequency: frequency),
              extra: { spam_count:, frequency: frequency, force_email: true }
            )
          end
        end

        private

        def count_spam(organization, frequency)
          since = frequency == :weekly ? 1.week.ago : 1.day.ago

          reports = Decidim::Report
                      .joins(:moderation)
                      .where(reason: "spam")
                      .where("decidim_reports.created_at >= ?", since)
                      .select do |report|
            begin
              reportable = report.moderation.reportable

              # Essaie de retrouver l’espace participatif
              participatory_space =
                if reportable.respond_to?(:component)
                  reportable.component.participatory_space
                elsif reportable.respond_to?(:commentable)
                  commentable = reportable.commentable
                  commentable.try(:component)&.participatory_space
                elsif reportable.respond_to?(:participatory_space)
                  reportable.participatory_space
                else
                  nil
                end

              next false unless participatory_space

              org_id = participatory_space.try(:decidim_organization_id) || participatory_space.try(:organization_id)
              org_id == organization.id
            rescue => e
              Rails.logger.debug "[Decidim-AI] ⚠️ Could not resolve org for report ##{report.id}: #{e.class} #{e.message}"
              false
            end
          end

          Rails.logger.info "[Decidim-AI] Found #{reports.size} potentials spams reports for #{organization.name}"
          reports.count
        end


      end
    end
  end
end
