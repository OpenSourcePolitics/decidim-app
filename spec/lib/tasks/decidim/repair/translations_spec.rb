# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:repair:translations", type: :task do
  let(:task) { Rake::Task[:"decidim:repair:translations"] }
  let!(:comment) { create(:comment) }
  let(:enable_machine_translations) { true }

  before do
    clear_enqueued_jobs
    clear_performed_jobs
    allow(Decidim).to receive(:enable_machine_translations).and_return(enable_machine_translations)
    allow(Decidim::RepairTranslationsService).to receive(:run).and_return([[Decidim::Comments::Comment, comment.id]])
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "calls the service" do
    task.execute
  end

  context "when translation is not activated" do
    let(:enable_machine_translations) { false }

    it "doesn't calls the service" do
      expect(Decidim::RepairTranslationsService).not_to receive(:run)

      task.execute
    end
  end

  describe "logging" do
    let!(:logger) { Logger.new($stdout) }

    before do
      # Stub the logger
      allow(logger).to receive(:info)
      allow(Logger).to receive(:new).and_return(logger)

      allow(Decidim::RepairTranslationsService).to receive(:run).and_return updated_resources_ids
    end

    context "when no nickname was repaired" do
      let(:updated_resources_ids) { [] }

      it "logs a message" do
        task.execute

        expect(logger).to have_received(:info).with("No resources updated")
      end
    end

    context "when some nicknames were repaired" do
      let(:updated_resources_ids) { [1, 2, 3] }

      it "logs a message" do
        task.execute

        expect(logger).to have_received(:info).with("Enqueued resources : 1, 2, 3")
      end
    end
  end
end
