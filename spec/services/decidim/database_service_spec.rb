# frozen_string_literal: true

require "spec_helper"

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
end
