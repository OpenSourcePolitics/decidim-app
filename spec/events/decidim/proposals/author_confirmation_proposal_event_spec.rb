# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe AuthorConfirmationProposalEvent do
      let(:user) { create :user, organization: organization }
      let(:resource) { create :extended_proposal }
      let(:participatory_process) { create :participatory_process, organization: organization }
      let(:proposal_component) { create(:extended_proposal_component, participatory_space: participatory_process) }
      let(:event_name) { "decidim.events.proposals.author_confirmation_proposal_event" }
      let(:user_role) { :participant }
      let(:extra) { {} }
      let(:organization) { resource.organization || create(:organization) }

      subject { described_class.new(resource: resource, event_name: event_name, user: user, user_role: user_role, extra: extra) }

      before do
        allow(subject).to receive(:participatory_space_title).and_return(participatory_process.title["en"])
      end

      describe "email_subject" do
        it "matches the expected translation" do
          expect(subject.email_subject).to eq("Your proposal has been published!")
        end
      end

      describe "email_outro" do
        it "matches the expected translation" do
          expected_outro = "You received this notification because you are the author of the proposal"
          expect(subject.email_outro).to include(expected_outro)
        end
      end
    end
  end
end
