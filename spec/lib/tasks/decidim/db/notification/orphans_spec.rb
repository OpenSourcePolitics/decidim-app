# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:db:notification:orphans", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "invokes the 'orphans' method" do
    stub = Decidim::NotificationService.new
    allow(Decidim::NotificationService).to receive(:new).and_return stub
    allow(stub).to receive(:orphans).and_return(true)

    task.execute

    expect(stub).to have_received(:orphans)
  end
end
