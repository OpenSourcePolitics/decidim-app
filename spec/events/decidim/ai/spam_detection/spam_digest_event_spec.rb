# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ai
    module SpamDetection
      describe SpamDigestEvent, type: :mailer do
        let(:organization) do
          create(:organization, name: { "en" => "Acme Org", "fr" => "Org Acme" })
        end
        let(:user) { create(:user, organization:, email: "admin@example.org") }

        shared_examples "the spam digest email" do |frequency, expected_text|
          let(:extra) { { spam_count: 25, frequency:, force_email: true } }

          it "generates and sends the digest email successfully" do
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
            expect(mail.body.encoded).to include("25")

            expect(mail.text_part).to be_present
            expect(mail.text_part.decoded).to include(expected_text)
            expect(mail.html_part.decoded).to include(expected_text) if mail.html_part.present?
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
