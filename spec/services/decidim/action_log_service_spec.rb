# frozen_string_literal: true

require "spec_helper"

describe Decidim::ActionLogService do
  subject { described_class.new }

  let!(:action_logs) { create_list(:action_log, 10) }

  describe "#orphans" do
    it "returns a Hash with count" do
      orphans = subject.orphans
      expect(orphans).to be_a Hash
      expect(orphans).to eq("Decidim::DummyResources::DummyResource" => 0)
    end

    context "when there is orphans data" do
      let!(:action_logs) { create_list(:action_log, 10) }

      before do
        Decidim::ActionLog.all.each { |actionlog| actionlog.resource.destroy }
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
      Decidim::ActionLog.all.each { |actionlog| actionlog.resource.destroy }
    end

    it "deletes directly the orphans data found" do
      expect do
        subject.clear
      end.to change(Decidim::ActionLog, :count).from(10).to(0)
    end
  end

  describe "#orphans_for" do
    context "when the class does not exist" do
      it "logs the error" do
        logger = Logger.new($stdout)
        allow(logger).to receive(:warn)
        described_class.new(logger: logger).send(:orphans_for, "NonExistingClass")

        expect(logger).to have_received(:warn).with("Skipping class : NonExistingClass")
      end
    end
  end
end
