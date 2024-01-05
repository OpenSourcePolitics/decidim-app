# frozen_string_literal: true

require "spec_helper"

require "migrations_fixer"

RSpec.describe MigrationsFixer do
  let(:logger) { Logger.new nil }
  let(:migration_path_env) { Rails.root.to_s }
  let(:instance) { described_class.new logger }

  before do
    @old_migration_path_env = ENV.fetch("MIGRATIONS_PATH", nil)
    ENV["MIGRATIONS_PATH"] = migration_path_env
  end

  after do
    ENV["MIGRATIONS_PATH"] = @old_migration_path_env # rubocop:disable RSpec/InstanceVariable
  end

  describe ".new" do
    context "with valid parameters" do
      it "sets the logger" do
        expect(instance.logger).to eq logger
      end

      it "sets the migrations path" do
        expect(instance.migrations_path).not_to be_blank
      end
    end

    context "with missing logger" do
      let(:logger) { nil }

      it "raises an exception" do
        expect do
          described_class.new logger
        end.to raise_error "Undefined logger"
      end
    end

    context "with missing environment" do
      let(:migration_path_env) { nil }

      it "raises an exception" do
        expect do
          described_class.new logger
        end.to raise_error "Invalid configuration, aborting"
      end
    end

    context "with non-existing MIGRATIONS_PATH variable" do
      let(:migration_path_env) { "/some/inexistant/dir" }

      it "raises an exception" do
        expect do
          described_class.new logger
        end.to raise_error "Invalid configuration, aborting"
      end
    end

    context "with missing project migrations" do
      it "raises an exception" do
        allow(ActiveRecord::Base.connection.migration_context.migrations_paths).to receive(:first).and_return "/some/invalid/directory"

        expect do
          described_class.new logger
        end.to raise_error "Invalid configuration, aborting"
      end
    end
  end
end
