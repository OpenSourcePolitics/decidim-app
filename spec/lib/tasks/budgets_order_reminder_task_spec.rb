# frozen_string_literal: true

require "spec_helper"

describe "rake budgets:remind_pending_order", type: :task do
  let(:task) { Rake::Task[:"budgets:remind_pending_order"] }

  after do
    clear_enqueued_jobs
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "performs a job" do
    expect(OrdersReminderJob).to receive(:perform_now)

    task.reenable
    task.invoke
  end
end
