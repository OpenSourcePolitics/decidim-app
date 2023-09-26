# frozen_string_literal: true

require "spec_helper"

require "decidim_app/k8s/manager"
require "decidim_app/k8s/command"
require "decidim_app/k8s/commands/organization"
require "decidim_app/k8s/commands/system_admin"
require "decidim_app/k8s/commands/admin"

describe DecidimApp::K8s::Command do
  subject { described_class.new }

  describe "#logger" do
    it "returns a logger" do
      expect(subject).to respond_to(:logger)
      expect(subject.logger).to be_a(LoggerWithStdout)
    end
  end

  describe "#topic" do
    it "responds to topic" do
      expect(subject).to respond_to(:topic)
    end

    it "raises error" do
      expect { subject.topic }.to raise_error(RuntimeError)
    end

    context "when topic registered" do
      before do
        subject.class.register_topic(:organization)
      end

      it "returns topic" do
        expect(subject.topic).to eq(:organization)
      end
    end
  end

  describe "#status_registry" do
    it "responds to status_registry" do
      expect(subject).to respond_to(:status_registry)
      expect(subject.status_registry).to be_a(Hash)
      expect(subject.status_registry).to eq({})
    end
  end
end
