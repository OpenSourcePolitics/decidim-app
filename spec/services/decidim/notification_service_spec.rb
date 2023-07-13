# frozen_string_literal: true

require "spec_helper"

describe Decidim::NotificationService do
  subject { described_class.new }

  let!(:notifications) { create_list(:notification, 10) }

  describe "#orphans" do
    it "returns a Hash with count" do
      orphans = subject.orphans
      expect(orphans).to be_a Hash
      expect(orphans).to eq("Decidim::DummyResources::DummyResource" => 0)
    end

    context "when there is orphans data" do
      let!(:notifications) { create_list(:notification, 10) }

      before do
        Decidim::Notification.all.each { |notif| notif.resource.destroy }
      end

      it "returns all orphans elements" do
        orphans = subject.orphans
        expect(orphans).to be_a Hash
        expect(orphans).to eq("Decidim::DummyResources::DummyResource" => 10)
      end
    end
  end

  describe "#clear" do
    before do
      Decidim::Notification.all.each { |notif| notif.resource.destroy }
    end

    it "destroys directly the orphans data found" do
      expect do
        subject.clear
      end.to change(Decidim::Notification, :count).from(10).to(0)
    end
  end
end
