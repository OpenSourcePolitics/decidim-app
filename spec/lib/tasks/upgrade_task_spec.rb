# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:upgrade", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "calls db:migrate" do
    expect(Rake::Task["db:migrate"]).to receive(:invoke)

    task.execute
  end
end
