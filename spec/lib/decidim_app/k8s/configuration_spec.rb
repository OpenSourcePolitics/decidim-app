# frozen_string_literal: true

require "spec_helper"
require "decidim_app/k8s/configuration"

describe DecidimApp::K8s::Configuration do
  subject { described_class.new(configuration_path) }

  let(:configuration_path) { "spec/fixtures/k8s_configuration_example.yml" }
  let(:configuration) { YAML.load_file(configuration_path).deep_symbolize_keys }

  describe "organizations" do
    context "when the configuration is not an array" do
      before do
        allow(YAML).to receive(:load_file).and_return({ organizations: { my_organization: "decidim" } })
      end

      it "returns an array" do
        expect(subject.organizations).to be_a(Array)
        expect(subject.organizations).to eq([{ my_organization: "decidim" }])
      end
    end

    it "returns the organization configuration" do
      expect(subject.organizations).to be_a(Array)
      expect(subject.organizations.first).to eq(configuration[:organizations].first)
    end
  end

  describe "default_admin" do
    it "returns the default admin configuration" do
      expect(subject.default_admin).to eq(configuration[:default_admin])
    end
  end

  describe "system_admin" do
    it "returns the system admin configuration" do
      expect(subject.system_admin).to eq(configuration[:system_admin])
    end
  end

  describe "valid?" do
    it { is_expected.to be_valid }

    context "when the configuration is invalid" do
      before do
        allow(YAML).to receive(:load_file).and_return({})
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe "errors" do
    it "returns the errors" do
      expect(subject.errors).to be_a(Array)
    end
  end
end
