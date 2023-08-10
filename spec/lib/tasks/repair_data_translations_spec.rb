# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:repair:translations", type: :task do
  let(:task) { Rake::Task[:"decidim:repair:translations"] }
  let!(:comment) { create(:comment) }

  before do
    clear_enqueued_jobs
    clear_performed_jobs
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
end
