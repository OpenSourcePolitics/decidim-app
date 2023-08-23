# frozen_string_literal: true

require "spec_helper"
require "json"

describe SentrySetup do
  let(:secrets) do
    {
      sentry: {
        enabled: true,
        dsn: "http://sentry.dsn",
        js_version: "4.6.4"
      }
    }
  end

  let(:server_metadata) do
    JSON.dump({
                hostname: "my_hostname",
                public_ip: {
                  address: "123.123.123.123"
                }
              })
  end

  before do
    allow(Rails.application).to receive(:secrets).and_return(secrets)
    allow(described_class).to receive(:`).with("scw-metadata-json").and_return(server_metadata)
    subject.init
  end

  describe ".init" do
    it "is configured" do
      expect(Sentry.configuration.dsn.host).to eq("sentry.dsn")
      expect(Sentry.configuration.traces_sample_rate).to eq(0.5)
    end

    context "when sentry is disabled" do
      let(:secrets) do
        {
          sentry: {
            enabled: false
          }
        }
      end

      let(:sentry) { double("Sentry") }

      it "is not configured" do
        expect(sentry).not_to receive(:init)
      end
    end
  end

  describe ".ip" do
    it "returns the ip" do
      expect(subject.send(:ip)).to eq("123.123.123.123")
    end

    context "when server_metadata is not available" do
      let(:server_metadata) { nil }

      it "returns nil" do
        expect(subject.send(:ip)).to be_nil
      end
    end
  end

  describe ".hostname" do
    it "returns the hostname" do
      expect(subject.send(:hostname)).to eq("my_hostname")
    end

    context "when server_metadata is not available" do
      let(:server_metadata) { {} }

      it "returns nil" do
        expect(subject.send(:hostname)).to be_nil
      end
    end
  end

  describe ".server_metadata" do
    context "when metadata are non-existent" do
      let(:server_metadata) { {} }

      it "returns nil" do
        expect(subject.send(:server_metadata)).to eq({})
      end
    end

    it "returns a metadata hash" do
      expect(subject.send(:server_metadata)).to be_a(Hash)
    end
  end

  describe ".sample rate" do
    it "returns the sample rate" do
      expect(subject.send(:sample_rate)).to eq("0.5")
    end

    context "when in a sidekiq worker" do
      before do
        allow(Sidekiq).to receive(:server?).and_return("constant")
      end

      it "returns the sample rate" do
        expect(subject.send(:sample_rate)).to eq("0.1")
      end
    end
  end
end
