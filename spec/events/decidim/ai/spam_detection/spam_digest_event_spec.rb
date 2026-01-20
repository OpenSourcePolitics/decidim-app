# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ai
    module SpamDetection
      describe SpamDigestEvent, type: :mailer do
        let(:organization) { create(:organization, name: { "en" => "Acme Org", "fr" => "Org Acme" }) }
        let(:other_organization) { create(:organization, name: { "en" => "Other Org" }) }
        let(:user) { create(:user, organization:, email: "admin@example.org") }
        let(:user_other) { create(:user, organization: other_organization) }
        let(:component) { create(:component, manifest_name: "proposals", organization:) }
        let(:component_other) { create(:component, manifest_name: "proposals", organization: other_organization) }
        let(:proposal) { create(:proposal, component:) }
        let(:proposal_other) { create(:proposal, component: component_other) }
        let(:moderation) { create(:moderation, reportable: proposal) }
        let(:moderation_other) { create(:moderation, reportable: proposal_other) }
        let(:since) { 1.day.ago }

        let(:normal_spams) do
          Decidim::Report
            .joins(:moderation)
            .where(reason: "spam")
            .where(decidim_reports: { created_at: since.. })
            .select { |r| r.moderation.participatory_space.organization == organization }
            .count
        end

        let(:user_spams) do
          Decidim::UserReport
            .joins(:user)
            .where(reason: "spam")
            .where(decidim_user_reports: { created_at: since.. })
            .where(decidim_users: { decidim_organization_id: organization.id })
            .count
        end

        let(:total_spams) { normal_spams + user_spams }

        before do
          create_list(:report, 2, moderation:, reason: "spam", created_at: Time.zone.now)
          create_list(:user_report, 1, reason: "spam", user:, created_at: Time.zone.now)

          # Older spams
          create_list(:report, 1, moderation:, reason: "spam", created_at: 5.days.ago)
          create_list(:user_report, 1, reason: "spam", user:, created_at: 5.days.ago)

          # Other organisation spams
          create_list(:report, 4, moderation: moderation_other, reason: "spam", created_at: Time.zone.now)
          create_list(:user_report, 3, reason: "spam", user: user_other, created_at: Time.zone.now)
        end

        shared_examples "the spam digest email" do |frequency, expected_text|
          let(:extra) { { spam_count: total_spams, frequency:, force_email: true } }

          it "generates and sends the digest email successfully with the right number of spam" do
            mail = nil

            expect do
              mail = Decidim::NotificationMailer
                     .event_received(
                       "decidim.events.ai.spam_detection.spam_digest_event",
                       "Decidim::Ai::SpamDetection::SpamDigestEvent",
                       organization,
                       user,
                       "follower",
                       extra
                     )
                     .deliver_now
            end.not_to raise_error

            expect(mail.to).to include("admin@example.org")
            expect(mail.subject).to match(/spam/i)
            expect(mail.body.encoded).to include(total_spams.to_s)
            expect(mail.body.encoded).to include("View detected spams")
            expect(mail.text_part).to be_present
            expect(mail.text_part.decoded).to include(expected_text)
            expect(mail.html_part.decoded).to include(expected_text) if mail.html_part.present?
          end
        end

        describe "Spam_count logic" do
          it "counts recent spam reports for the correct organization" do
            expect(normal_spams).to eq(2)
            expect(user_spams).to eq(1)
            expect(total_spams).to eq(3)
          end
        end

        context "when frequency is daily" do
          it_behaves_like "the spam digest email", :daily, "today"
        end

        context "when frequency is weekly" do
          it_behaves_like "the spam digest email", :weekly, "this week"
        end
      end
    end
  end
end
