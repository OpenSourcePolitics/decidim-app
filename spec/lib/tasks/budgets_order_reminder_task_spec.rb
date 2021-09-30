# frozen_string_literal: true

require "spec_helper"

describe "rake budgets:remind_pending_order", type: :task do
  let(:task) { Rake::Task[:"budgets:remind_pending_order"] }

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

  it "performs a job" do
    task.reenable

    expect { task.invoke }.to have_enqueued_job(OrdersReminderJob).at_least(:once)
  end
end
