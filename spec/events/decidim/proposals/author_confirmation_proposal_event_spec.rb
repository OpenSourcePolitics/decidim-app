# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe AuthorConfirmationProposalEvent do
      let(:resource) { create :extended_proposal }
      let(:participatory_process) { create :participatory_process, organization: organization }
      let(:proposal_component) { create(:extended_proposal_component, participatory_space: participatory_process) }
      let(:resource_title) { decidim_sanitize_translated(resource.title) }
      let(:event_name) { "decidim.events.proposals.author_confirmation_proposal_event" }

      include_context "when a simple event"

      it_behaves_like "a simple event"

      describe "resource_text" do
        it "returns the proposal body" do
          expect(subject.resource_text).to be(resource.body)
        end
      end

      describe "email_subject" do
        it "matches the expected translation" do
          expect(subject.email_subject).to be("Your proposal has been published!")
        end
      end

      describe "email_intro" do
        it "matches the expected translation" do
          expected_intro = "Your proposal \"#{resource_title}\" was successfully received and is now public. Thank you for participating! Here it is: <a href=\"#{resource_path}\">#{resource_title}</a>."
          expect(subject.email_intro).to be(expected_intro)
        end
      end

      describe "email_outro" do
        it "matches the expected translation" do
          expected_outro = "You have received this notification because you are the author of the proposal. You can unfollow it by going to the proposal page (\"#{resource_title}\") and clicking on \"Unfollow\"."
          expect(subject.email_outro).to be(expected_outro)
        end
      end

      describe "notification_title" do
        it "matches the expected translation" do
          expected_title = "Your proposal <a href=\"#{resource_path}\">#{resource_title}</a> is now live."
          expect(subject.notification_title).to be(expected_title)
        end
      end

      describe "translated notifications" do
        let(:en_body) { "A nice proposal" }
        let(:body) { { en: en_body, machine_translations: { ca: "Une belle idee" } } }
        let(:resource) do
          create :extended_proposal,
                 component: proposal_component,
                 title: { en: "A nice proposal", machine_translations: { ca: "Une belle idee" } },
                 body: body
        end

        let(:en_version) { subject.resource_text["en"] }
        let(:machine_translated) { subject.resource_text["machine_translations"]["ca"] }
        let(:translatable) { true }

        it_behaves_like "a translated event"
      end
    end
  end
end
