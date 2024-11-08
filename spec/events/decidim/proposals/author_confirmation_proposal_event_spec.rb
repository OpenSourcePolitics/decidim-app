# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe ProposalPublishedEvent do
      let(:organization) { create(:organization) }
      let(:author) { create(:user, organization: organization) }
      let(:resource) { create(:proposal, component: proposal_component, title: { en: "Proposition de test" }, body: { en: "Corps de la proposition" }) }
      let(:participatory_process) { create(:participatory_process, organization: organization) }
      let(:proposal_component) { create(:component, manifest_name: :proposals, participatory_space: participatory_process) }
      let(:resource_title) { decidim_sanitize_translated(resource.title) }
      let(:resource_path) { Decidim::ResourceLocatorPresenter.new(resource).path }
      let(:event_name) { "decidim.events.proposals.proposal_published" }

      subject { described_class.new(resource: resource, event_name: event_name, user: author) }

      describe "email_subject" do
        it "matches the expected translation" do
          expect(subject.email_subject).to eq(I18n.t("decidim.proposals.notifications.proposal_published.subject"))
        end
      end

      describe "email_intro" do
        it "matches the expected translation" do
          expected_intro = I18n.t("decidim.proposals.notifications.proposal_published.email_intro", resource_title: resource_title, resource_path: resource_path)
          expect(subject.email_intro).to eq(expected_intro)
        end
      end

      describe "email_outro" do
        it "matches the expected translation" do
          expected_outro = I18n.t("decidim.proposals.notifications.proposal_published.email_outro", resource_title: resource_title)
          expect(subject.email_outro).to eq(expected_outro)
        end
      end

      describe "notification_title" do
        it "matches the expected translation" do
          expected_title = I18n.t("decidim.proposals.notifications.proposal_published.notification_title", resource_title: resource_title, resource_path: resource_path)
          expect(subject.notification_title).to eq(expected_title)
        end
      end

      describe "resource_text" do
        it "returns the proposal body" do
          expect(subject.resource_text).to eq(resource.body)
        end
      end
    end
  end
end
