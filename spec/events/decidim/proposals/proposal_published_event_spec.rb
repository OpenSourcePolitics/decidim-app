# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

module Decidim::Proposals
  describe "ProposalPublishedEvent", type: :job do
    include MailerHelpers

    let(:organization) { create(:organization) }
    let(:participatory_process) { create(:participatory_process, organization: organization) }
    let(:component) { create(:component, manifest_name: :proposals, participatory_space: participatory_process) }
    let!(:proposal_state) { create(:proposal_state, component: component) }
    let(:proposal) { create(:proposal, component: component, proposal_state: proposal_state, title: { en: "Test proposition notification" }) }
    let(:user) { create(:user, :admin, organization: organization, notifications_sending_frequency: "daily") }

    before do
      clear_emails
    end

    context "when proposal is published" do

      it "sends a notification email with the correct content" do
        subject { ProposalPublishedEvent.new(resource: proposal, event_name: "decidim.proposals.proposal_published", user: proposal.creator_identity) }
        expect(last_email).not_to be_nil
        expect(last_email_body).not_to include("translation missing")
        expect(last_email_body).to include("Test proposition notification")
      end

      it "sends a notification with the correct content" do
        subject { ProposalPublishedEvent.new(resource: proposal, event_name: "decidim.proposals.proposal_published", user: proposal.creator_identity) }
        notification = Decidim::Notification.last
        # Parse avec Nokogiri
        html_body = Nokogiri::HTML(notification.extra["body"])
        text = html_body.text
        expect(text).to eq("Your proposal Test proposition notification has been published")

        expect(notification).not_to be_nil
      end
    end
  end
end
#
# shared_context "when sends the notification digest" do
#   context "when daily notification mail" do
#     let(:user) { create(:user, :admin, organization:, notifications_sending_frequency: "daily") }
#
#     it_behaves_like "notification digest mail"
#   end
#
#   context "when weekly notification mail" do
#     let(:user) { create(:user, :admin, organization:, notifications_sending_frequency: "weekly") }
#
#     it_behaves_like "notification digest mail"
#   end
# end
#
# shared_examples_for "notification digest mail" do
#   context "when a notifiable event takes place" do
#     let!(:organization) { create(:organization) }
#     let!(:participatory_space) { create(:participatory_process, organization:) }
#
#     it "sends a notification to the user's email" do
#       perform_enqueued_jobs do
#         expect(command.call).to broadcast(:ok)
#         Decidim::Notification.last.update(created_at: 1.day.ago)
#         Decidim::EmailNotificationsDigestGeneratorJob.perform_now(user.id, user.notifications_sending_frequency)
#       end
#
#       expect(last_email_body.length).to be_positive
#       expect(last_email_body).not_to include("translation missing")
#     end
#   end
# end
