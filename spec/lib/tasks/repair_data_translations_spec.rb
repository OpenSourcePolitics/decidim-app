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
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "calls the service" do
    expect(Decidim::RepairTranslationsService).to receive(:run).and_return([[Decidim::Comments::Comment, comment.id]])

    task.execute
  end

  context "when translation is not activated" do
    let(:enable_machine_translations) { false }

    it "doesn't calls the service" do
      expect(Decidim::RepairTranslationsService).not_to receive(:run)

      task.execute
    end
  end
end
