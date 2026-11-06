# frozen_string_literal: true

require "spec_helper"
# Production-only gem (Gemfile :production group): load it for this spec.
require "active_job/uniqueness"

describe Decidim::OpenDataJob do
  before(:all) { described_class.include(OpenDataJobExtends) } # rubocop:disable RSpec/BeforeAfterAll

  after(:all) { described_class.lock_strategy_class = nil } # rubocop:disable RSpec/BeforeAfterAll

  let(:organization) { create(:organization) }

  # In-memory stand-in for the Redis lock manager: first lock wins.
  let(:lock_manager) do
    Class.new do
      def initialize = @locks = {}

      def lock(resource, _ttl) = @locks.has_key?(resource) ? false : (@locks[resource] = true)

      def delete_lock(resource) = @locks.delete(resource)

      def delete_locks(*) = @locks.clear
    end.new
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(ActiveJob::Uniqueness).to receive(:lock_manager).and_return(lock_manager)
  end

  it "is unique until executed, with a lock TTL and logging on conflict" do
    expect(described_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuted)
    expect(described_class.lock_options).to eq(lock_ttl: 1.hour, on_conflict: :log)
  end

  it "enqueues a single job when the same resource is requested twice" do
    expect do
      described_class.perform_later(organization, "users")
      expect(described_class.perform_later(organization, "users")).to be(false)
    end.to have_enqueued_job(described_class).exactly(:once)
  end

  it "enqueues one job per resource" do
    expect do
      described_class.perform_later(organization, "users")
      described_class.perform_later(organization, "proposals")
      described_class.perform_later(organization)
    end.to have_enqueued_job(described_class).exactly(3).times
  end

  it "releases the lock once the export is done" do
    allow(Decidim::OpenDataExporter).to receive(:new) do |_organization, path, _resource|
      instance_double(Decidim::OpenDataExporter, export: File.write(path, "id\n"))
    end

    described_class.perform_now(organization, "taxonomies")

    expect { described_class.perform_later(organization, "taxonomies") }.to have_enqueued_job(described_class).exactly(:once)
  end
end
