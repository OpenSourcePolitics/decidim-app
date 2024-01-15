# frozen_string_literal: true

require "spec_helper"

class FakeDatabaseService < Decidim::DatabaseService
  def initialize(resource_types: nil, **args)
    @resource_types = resource_types

    super(**args)
  end

  def resource_types # rubocop:disable Style/TrivialAccessors
    @resource_types
  end
end

describe Decidim::DatabaseService do
  subject { described_class.new }

  describe "#resource_types" do
    it "raises RuntimeError exception" do
      expect do
        subject.send(:resource_types)
      end.to raise_error RuntimeError, "Method resource_types isn't defined for Decidim::DatabaseService"
    end
  end

  describe "#orphans_for" do
    it "raises RuntimeError exception" do
      expect do
        subject.send(:orphans_for, nil)
      end.to raise_error RuntimeError, "Method orphans_for isn't defined for Decidim::DatabaseService"
    end
  end

  describe "#clear_data_for" do
    it "raises RuntimeError exception" do
      expect do
        subject.send(:clear_data_for, nil)
      end.to raise_error RuntimeError, "Method clear_data_for isn't defined for Decidim::DatabaseService"
    end
  end

  describe "when used as class parent" do
    let(:fake_instance) { FakeDatabaseService.new(**instance_args) }
    let(:instance_args) { {} }

    describe "#orphans" do
      context "with no resource type" do
        let(:instance_args) { { resource_types: nil } }

        it "returns nil" do
          expect(fake_instance.orphans).to be_nil
        end
      end
    end
  end
end
