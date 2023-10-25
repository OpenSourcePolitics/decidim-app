# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::S3SyncService do
  let(:temp_directory) { Dir.mktmpdir }
  let(:options) { {} }
  let(:instance) { described_class.new(options) }

  after do
    FileUtils.rm_rf temp_directory
  end

  describe ".run" do
    it "executes the service" do
      allow(described_class).to receive(:new).with(options).and_return instance
      allow(instance).to receive(:execute).and_return "__success__"

      expect(described_class.run({})).to eq "__success__"
    end
  end

  describe "#default_options" do
    let(:option_keys) { instance.default_options.keys }

    it "returns a hash" do
      expect(instance.default_options).to be_a Hash
    end

    it "has keys existing in backup configuration" do
      config_keys = Rails.application.config.backup[:s3sync].keys
                         .map { |k| "s3_#{k}".to_sym }

      aggregate_failures do
        option_keys.filter { |k| k.match?(/^s3_/) }.each do |key|
          expect(config_keys).to include key
        end
      end
    end
  end

  describe "#has_local_backup_directory?" do
    let(:options) { { local_backup_dir: temp_directory } }

    context "when the directory exists and is readable" do
      it "returns true" do
        expect(instance.has_local_backup_directory?).to be true
      end
    end

    context "when the directory does not exists" do
      before { FileUtils.rm_rf temp_directory }

      it "returns false" do
        expect(instance.has_local_backup_directory?).to be false
      end
    end

    context "when the directory exists but is not readable" do
      before { FileUtils.chmod("ugo=wx", temp_directory) }

      it "returns false" do
        expect(instance.has_local_backup_directory?).to be false
      end
    end
  end

  describe "#subfolder" do
    it "returns a memoized string" do
      subfolder = instance.subfolder

      expect(subfolder).to be_a String
      expect(instance.instance_variable_get(:@subfolder)).to eq subfolder
    end

    context "with an option given" do
      let(:options) { { subfolder: "something" } }

      it "uses the given path" do
        expect(instance.subfolder).to eq "something"
      end
    end

    context "without an option given" do
      it "generates a path" do
        expect(instance.subfolder).not_to be_blank
      end
    end
  end

  describe "#force_upload?" do
    context "when option was not provided" do
      it "defaults to false" do
        expect(instance.force_upload?).to be false
      end
    end

    [true, false].each do |state|
      context "when option was set to #{state}" do
        let(:options) { { force_upload: state } }

        it "returns #{state}" do
          expect(instance.force_upload?).to be state
        end
      end
    end
  end

  describe "#timestamp" do
    it "returns a memoized string" do
      timestamp = instance.timestamp

      expect(timestamp).to be_a String
      expect(instance.instance_variable_get(:@timestamp)).to eq timestamp
    end
  end

  describe "#file_list" do
    context "when no file list was provided" do
      let(:options) { { local_backup_dir: temp_directory } }

      before do
        Dir.chdir(temp_directory) { `touch file_1.txt file_2.txt` }
      end

      it "reads from the backup directory" do
        expected = [
          "#{temp_directory}/file_1.txt",
          "#{temp_directory}/file_2.txt"
        ]
        expect(instance.file_list.sort).to eq expected
      end
    end

    context "when both a file list and a directory are provided" do
      let(:options) do
        {
          local_backup_dir: temp_directory,
          local_backup_files: %w(file_list_1.txt file_list_2.txt)
        }
      end

      before do
        Dir.chdir(temp_directory) { `touch file_1.txt file_2.txt` }
      end

      it "reads from the file list" do
        expected = [
          "file_list_1.txt",
          "file_list_2.txt"
        ]

        expect(instance.file_list.sort).to eq expected
      end
    end
  end

  describe "#service" do
    it "memoizes the storage service" do
      allow(Fog::Storage).to receive(:new).and_return("__success__")

      2.times { instance.send(:service) }
      expect(Fog::Storage).to have_received(:new).once
    end
  end
end
