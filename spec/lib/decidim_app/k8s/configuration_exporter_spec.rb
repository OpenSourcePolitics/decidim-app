# frozen_string_literal: true

require "spec_helper"
require "decidim_app/k8s/configuration_exporter"

describe DecidimApp::K8s::ConfigurationExporter do
  subject { described_class.new(image) }

  let(:organization) { create(:organization) }
  let(:image) { "registry.gitlab.com/my-image" }
  let(:enable_sync) { true }

  describe "#clean_migration_directory" do
    it "cleans the migration directory" do
      expect(FileUtils).to receive(:rm_rf).with(described_class::EXPORT_PATH)
      expect(FileUtils).to receive(:mkdir_p).with(described_class::EXPORT_PATH)

      subject.clean_migration_directory
    end
  end

  describe "#export!" do
    it "exports the organizations" do
      expect(DecidimApp::K8s::OrganizationExporter).to receive(:export!).with(organization, subject.instance_variable_get(:@logger), described_class::EXPORT_PATH, image).and_return(true)

      subject.export!
    end
  end

  describe ".export!" do
    it "creates a new instance and calls export!" do
      # rubocop:disable RSpec/AnyInstance
      expect_any_instance_of(described_class).to receive(:export!)
      # rubocop:enable RSpec/AnyInstance

      described_class.export!(image)
    end
  end
end
