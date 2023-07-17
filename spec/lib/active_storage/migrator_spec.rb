# frozen_string_literal: true

require "spec_helper"
require "active_storage/migrator"

describe ActiveStorage::Migrator do
  subject { described_class.new(source, destination) }

  let(:source) { :local }
  let(:destination) { :scaleway }

  let(:configuration) do
    {
      local: {
        service: "Disk",
        root: Rails.root.join("storage").to_s
      },
      scaleway: {
        service: "S3",
        endpoint: "https://s3.fr-par.dummy.org",
        access_key_id: "dummy-access-key-id",
        secret_access_key: "dummy-secret-access-key",
        region: "fr-par",
        bucket: "dummy-bucket"
      }
    }
  end

  before do
    allow(Rails.configuration.active_storage).to receive(:service_configurations).and_return(configuration)
  end

  describe "#initialize" do
    it "sets the source service" do
      expect(subject.instance_variable_get(:@source_service)).to be_a(ActiveStorage::Service::DiskService)
    end

    it "sets the destination service" do
      expect(subject.instance_variable_get(:@destination_service)).to be_a(ActiveStorage::Service::S3Service)
    end

    it "sets the logger" do
      expect(subject.instance_variable_get(:@logger)).to be_a(LoggerWithStdout)
    end

    context "when the source is unknown" do
      let(:source) { :unknown }

      it "raises an error" do
        expect { subject }.to raise_error("Unknown provider unknown")
      end
    end
  end

  describe ".migrate!" do
    it "creates a new instance and calls #migrate!" do
      allow(described_class).to receive(:new).with(source, destination).and_return(subject)
      # rubocop:disable RSpec/SubjectStub
      expect(subject).to receive(:migrate!)
      # rubocop:enable RSpec/SubjectStub

      described_class.migrate!(source, destination)
    end
  end

  describe "#migrate!" do
    let(:blob) { ActiveStorage::Blob.create_and_upload!(io: File.open(Rails.root.join("spec/test_assets/logo_asset.png")), filename: "logo_asset.png") }

    before do
      allow(ActiveStorage::Blob).to receive(:find_each).and_yield(blob)
    end

    it "migrates the blobs" do
      allow(blob).to receive(:open).and_yield(Tempfile.new("blob"))
      expect(subject.instance_variable_get(:@destination_service)).to receive(:upload).with(blob.key, anything, checksum: blob.checksum)

      subject.migrate!
    end

    context "when the blob is not found" do
      before do
        allow(blob).to receive(:open).and_raise(ActiveStorage::FileNotFoundError)
      end

      it "logs the error" do
        expect(subject.instance_variable_get(:@logger)).to receive(:error).with("FileNotFoundError #{blob.key}")

        subject.migrate!
      end
    end
  end
end
