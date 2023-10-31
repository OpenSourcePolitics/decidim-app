# frozen_string_literal: true

require "spec_helper"

require "rails_migrations"
require "migrations_fixer"

class FakeMigrationsFixer
  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def osp_app_path
    "/some/dir"
  end

  def migrations_path
    "/something_else"
  end
end

RSpec.describe RailsMigrations do
  let(:logger) { Logger.new nil }
  let(:migration_fixer) { FakeMigrationsFixer.new logger }
  let(:instance) { described_class.new migration_fixer }
  let(:migrations_status) do
    [
      ["up", "20230824135802", "Change something in db structure"],
      ["down", "20230824135803", "Change something else"],
      ["down", "20230824135804", "********** NO FILE **********"]
    ]
  end

  before do
    allow(instance).to receive(:migration_status).and_return migrations_status
    instance.reload_migrations!
  end

  describe "#reload_down!" do
    it "reloads and find down migrations" do
      allow(instance).to receive(:reload_migrations!)
      allow(instance).to receive(:down)

      instance.reload_down!

      aggregate_failures do
        expect(instance).to have_received(:reload_migrations!)
        expect(instance).to have_received(:down)
      end
    end
  end

  describe "#down" do
    it "returns all migrations marked 'down'" do
      expect(instance.down.size).to eq 2
    end
  end

  describe "#reload_migrations!" do
    it "resets @fetch_all" do
      new_list = [1, 2, 3]
      allow(instance).to receive(:migration_status).and_return new_list

      instance.reload_migrations!
      expect(instance.fetch_all).to eq new_list
    end
  end

  describe "#display_status!" do
    it "logs statuses" do
      allow(logger).to receive(:info)

      instance.display_status!

      expect(logger).to have_received(:info).exactly(3).times
    end
  end

  describe "#not_found" do
    it "returns the amount of missing migrations files" do
      expect(instance.not_found.size).to eq 1
    end
  end

  describe "#versions_down_but_already_passed" do
    it "returns the list of possible files for missing versions" do
      allow(Dir).to receive(:glob).and_return ["20230824135804_change_something_else_again.rb"]
      expect(instance.versions_down_but_already_passed).to eq ["20230824135804"]
    end
  end
end
