# frozen_string_literal: true

require "spec_helper"

describe DecidimApp::Config do
  describe "#proxy_present?" do
    before do
      allow(described_class).to receive(:trusted_proxies).and_return(["127.0.0.1"])
    end

    it "returns true" do
      expect(described_class).to be_proxy_present
    end

    context "when trusted_proxies is empty" do
      before do
        allow(described_class).to receive(:trusted_proxies).and_return([])
      end

      it "returns false" do
        expect(described_class).not_to be_proxy_present
      end
    end
  end

  describe "#trusted_proxies" do
    it "returns empty array" do
      expect(described_class.trusted_proxies).to eq([])
    end

    context "when decidim rack_attack trusted_proxies secret is set" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :trusted_proxies).and_return(["127.0.0.1"])
      end

      it "returns array of string" do
        expect(described_class.trusted_proxies).to eq(["127.0.0.1"])
      end
    end
  end
end
