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
      expect(subject.organizations.first[:name]).to eq("OSP Decidim")
      expect(subject.organizations.last[:name]).to eq("OSP Decidim 2")

      expect(subject.organizations.first[:secondary_hosts]).to eq("osp.example.org\nosp.decidim.example")

      file_upload_settings = subject.organizations.first[:file_upload_settings]
      expect(file_upload_settings[:allowed_file_extensions][:admin]).to eq("jpeg,jpg,gif,png,bmp,pdf,doc,docx,xls,xlsx,ppt,pptx,ppx,rtf,txt,odt,ott,odf,otg,ods,ots")
      expect(file_upload_settings[:allowed_file_extensions][:image]).to eq("jpg,jpeg,gif,png,bmp,ico")
      expect(file_upload_settings[:allowed_file_extensions][:default]).to eq("jpg,jpeg,gif,png,bmp,pdf,rtf,txt")
      expect(file_upload_settings[:allowed_content_types][:admin]).to eq("image/*,application/vnd.oasis.opendocument,application/vnd.ms-*,application/msword,application/vnd.ms-word,application/vnd.openxmlformats-officedocument,application/vnd.oasis.opendocument,application/pdf,application/rtf,text/plain")
      expect(file_upload_settings[:allowed_content_types][:default]).to eq("image/*,application/pdf,application/rtf,text/plain")
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
