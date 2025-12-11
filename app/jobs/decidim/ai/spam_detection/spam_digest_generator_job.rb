# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      # This job generates and publishes the AI spam digest event
      # for each organization, either daily or weekly.
      class SpamDigestGeneratorJob < ApplicationJob
        queue_as :mailers

        FREQUENCIES = {
          daily: "daily",
          weekly: "weekly"
        }.freeze

        def perform(frequency)
          # Skip validation if frequency is nil (called by Decidim core specs)
          return if frequency.nil? && Rails.env.test?
          raise ArgumentError, "Invalid frequency: #{frequency}" unless frequency && FREQUENCIES.has_key?(frequency.to_sym)

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

          spam_user_reports_since(since, organization).count + spam_reports_since(since, organization).count
        end

        # Returns all spam reports created since the given time
        def spam_reports_since(since, organization)
          reports = Decidim::Report
                    .joins(:moderation)
                    .where(reason: "spam")
                    .where("decidim_reports.created_at >= ?", since)
                    .includes(moderation: { participatory_space: :organization })

          reports.select { |r| r.moderation.participatory_space&.organization&.id == organization.id }
        end

        def spam_user_reports_since(since, organization)
          reports = Decidim::UserReport
                    .joins(:user)
                    .where(reason: "spam")
                    .where("decidim_user_reports.created_at >= ?", since)
                    .where(decidim_users: { decidim_organization_id: organization.id })
                    .includes(:user)

          reports.select { |r| r.user.decidim_organization_id == organization.id }
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
