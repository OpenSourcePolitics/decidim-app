# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      # This job generates and publishes the AI spam digest event
      # for each organization, either daily or weekly.
      class SpamDigestGeneratorJob < ApplicationJob
        queue_as :mailers

        def perform(frequency)
          Decidim::Organization.find_each do |organization|
            admins = organization.admins.where(notifications_sending_frequency: frequency)
            next if admins.empty?

            spam_count = count_spam(organization, frequency)
            next if spam_count.zero?

            Decidim::EventsManager.publish(
              event: "decidim.events.ai.spam_detection.spam_digest_event",
              event_class: Decidim::Ai::SpamDetection::SpamDigestEvent,
              resource: organization,
              followers: admins,
              extra: { spam_count:, frequency:, force_email: true }
            )
          end
        end

        private

        # Counts the spam reports for the given organization and frequency (daily/weekly)
        def count_spam(organization, frequency)
          since = frequency == :weekly ? 1.week.ago : 1.day.ago

          general_spams = spam_reports_since(since).count do |report|
            report_belongs_to_org?(report, organization)
          end

          user_spams = spam_user_reports_since(since).where(decidim_users: { decidim_organization_id: organization.id }).count

          user_spams + general_spams
        end

        # Returns all spam reports created since the given time
        def spam_reports_since(since)
          Decidim::Report
            .joins(:moderation)
            .where(reason: "spam")
            .where("decidim_reports.created_at >= ?", since)
        end

        def spam_user_reports_since(since)
          Decidim::UserReport
            .joins(:user)
            .where(reason: "spam")
            .where("decidim_user_reports.created_at >= ?", since)
        end

        # Determines if a spam report belongs to the given organization
        def report_belongs_to_org?(report, organization)
          reportable = report.moderation.reportable

          participatory_space = find_participatory_space(reportable)
          return false unless participatory_space

          org_id = participatory_space.try(:decidim_organization_id) || participatory_space.try(:organization_id)
          org_id == organization.id
        rescue StandardError => e
          Rails.logger.debug do
            "[Decidim-AI] ⚠️ Could not resolve organization for report ##{report.id}: #{e.class} #{e.message}"
          end
          false
        end

        # Finds the participatory space for a given reportable entity
        def find_participatory_space(reportable)
          if reportable.respond_to?(:component)
            reportable.component.participatory_space
          elsif reportable.respond_to?(:commentable)
            commentable = reportable.commentable
            commentable.try(:component)&.participatory_space
          elsif reportable.respond_to?(:participatory_space)
            reportable.participatory_space
          end
        end
      end
    end
  end
end
