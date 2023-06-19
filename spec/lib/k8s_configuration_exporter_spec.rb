# frozen_string_literal: true

require "spec_helper"
require "k8s_configuration_exporter"

describe K8sConfigurationExporter do
  subject { described_class.new(image, enable_sync) }

  let(:organization) { create(:organization) }
  let(:image) { "registry.gitlab.com/my-image" }
  let(:enable_sync) { true }
  let(:hostname) { "123.123.123.123" }

  before do
    allow(Socket).to receive(:gethostname).and_return(hostname)
  end

  describe "#hostname" do
    it "returns the hostname" do
      expect(subject.hostname).to eq("123-123-123-123")
    end
  end

  describe "#perform_sync" do
    it "syncs the export to the bucket" do
      # rubocop:disable RSpec/SubjectStub
      expect(subject).to receive(:system).with("rclone delete scw-migration:123-123-123-123-migration --rmdirs --config ../scaleway.config")
      expect(subject).to receive(:system).with("rclone copy #{described_class::EXPORT_PATH} scw-migration:123-123-123-123-migration --config ../scaleway.config --progress --copy-links")
      # rubocop:enable RSpec/SubjectStub

      subject.perform_sync
    end

    context "when enable_sync is false" do
      let(:enable_sync) { false }

      it "does not sync the export to the bucket" do
        # rubocop:disable RSpec/SubjectStub
        expect(subject).not_to receive(:system)
        # rubocop:enable RSpec/SubjectStub

        subject.perform_sync
      end
    end
  end

  describe "#clean_migration_directory" do
    it "cleans the migration directory" do
      expect(FileUtils).to receive(:rm_rf).with(described_class::EXPORT_PATH)
      expect(FileUtils).to receive(:mkdir_p).with(described_class::EXPORT_PATH)

      subject.clean_migration_directory
    end
  end

  describe "#export!" do
    it "exports the organizations" do
      expect(K8sOrganizationExporter).to receive(:export!).with(organization, subject.instance_variable_get(:@logger), described_class::EXPORT_PATH, "123-123-123-123", image).and_return(true)

      subject.export!
    end
  end

  describe ".export!" do
    it "creates a new instance and calls export!" do
      # rubocop:disable RSpec/AnyInstance
      expect_any_instance_of(described_class).to receive(:export!)
      # rubocop:enable RSpec/AnyInstance

      described_class.export!(image, enable_sync)
    end
  end
end
