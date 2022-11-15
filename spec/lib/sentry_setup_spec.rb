# frozen_string_literal: true

require "spec_helper"

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

  before do
    allow(Rails.application).to receive(:secrets).and_return(secrets)
    subject.init
  end

  describe ".init" do
    it "is configured" do
      expect(Sentry.configuration.dsn.host).to eq("sentry.dsn")
      expect(Sentry.configuration.traces_sample_rate).to eq(1.0)
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
    let(:hostname_command_output) { false }

    before do
      allow(described_class).to receive(:`).with("hostname").and_return("my_hostname")
      allow(described_class).to receive(:`).with("hostname -I").and_return("123.123.123.123 2001:bc7:4764:1b1a::3")
      allow(described_class).to receive(:system).with("hostname -I > /dev/null 2>&1").and_return(hostname_command_output)
    end

    it "returns nil" do
      expect(subject.send(:ip)).to eq(nil)
    end

    context "when hostname -I is defined" do
      let(:hostname_command_output) { true }

      it "returns ip" do
        expect(subject.send(:ip)).to eq("123.123.123.123")
      end
    end
  end
end
