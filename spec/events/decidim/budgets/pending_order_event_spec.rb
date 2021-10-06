# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/simple_event"

describe Decidim::Budgets::PendingOrderEvent do
  let(:resource) { create :budget }
  let(:event_name) { "decidim.events.budgets.pending_order" }

  include_context "when a simple event"
  it_behaves_like "a simple event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("Your vote is still pending in #{participatory_space_title}")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro).to eq("The vote on budget \"#{resource_title}\" is not confirmed yet in \"#{participatory_space_title}\".")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to include("You have received this notification because you are participating in \"#{participatory_space_title}\"")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to eq("The vote on budget <a href=\"#{resource_path}\">#{resource_title}</a> is still waiting for your confirmation in #{participatory_space_title}")
    end
  end

  describe "resource_text" do
    it "returns the budget title" do
      expect(subject.resource_text).to eq translated(resource.title)
    end
  end
end
