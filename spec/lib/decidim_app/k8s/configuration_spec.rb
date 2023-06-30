# frozen_string_literal: true

require "spec_helper"
require "decidim-app/k8s/configuration"

describe DecidimApp::K8s::Configuration do
  subject { described_class.new(configuration) }

  let(:configuration) do
    {
      "organizations" => organization_configuration,
      "default_admin" => default_admin_configuration,
      "system_admin" => system_admin_configuration
    }
  end

  let(:organization_configuration) do
    [
      { "organization" => "foo" }
    ]
  end

  let(:default_admin_configuration) do
    { "default_admin" => "John Doe" }
  end

  let(:system_admin_configuration) do
    { "system_admin" => "SUPER_ADMIN" }
  end

  describe "organizations" do
    context "when the configuration is not an array" do
      let(:organization_configuration) do
        { "my_organization" => "decidim" }
      end

      it "returns an array" do
        expect(subject.organizations).to be_a(Array)
        expect(subject.organizations).to eq([{ "my_organization" => "decidim" }])
      end
    end

    it "returns the organization configuration" do
      expect(subject.organizations).to be_a(Array)
      expect(subject.organizations.first).to eq({ "organization" => "foo" })
    end
  end

  describe "default_admin" do
    it "returns the default admin configuration" do
      expect(subject.default_admin).to eq({ "default_admin" => "John Doe" })
    end
  end

  describe "system_admin" do
    it "returns the system admin configuration" do
      expect(subject.system_admin).to eq({ "system_admin" => "SUPER_ADMIN" })
    end
  end

  describe "valid?" do
    it { is_expected.to be_valid }

    context "when the configuration is invalid" do
      let(:configuration) { {} }

      it { is_expected.not_to be_valid }
    end
  end

  describe "errors" do
    it "returns the errors" do
      expect(subject.errors).to be_a(Array)
    end
  end
end
