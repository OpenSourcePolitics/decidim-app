# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::S3RetentionService do
  let(:options) { {} }
  let(:instance) { described_class.new(options) }

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
        option_keys.each do |key|
          expect(config_keys).to include key
        end
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

  describe "#retention_dates" do
    let(:retention_dates) { instance.retention_dates }

    it "returns an array" do
      expect(instance.retention_dates).to be_a Array
    end

    it "contains no duplicates" do
      expect(retention_dates.size).to eq retention_dates.uniq.size
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
