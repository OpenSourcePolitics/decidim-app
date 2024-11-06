# frozen_string_literal: true

require "spec_helper"

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
      subject { ProposalPublishedEvent.new(resource: proposal, event_name: "decidim.proposals.proposal_published", user: proposal.creator_identity) }
      it "sends a notification email with the correct content" do

        expect(last_email).not_to be_nil
        expect(last_email_body).not_to include("translation missing")
        expect(last_email_body).to include("Test proposition notification")
      end

      it "sends a notification with the correct content" do
        notification = Decidim::Notification.last
        expect(notification).not_to be_nil
      end
    end
  end
end
