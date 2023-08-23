# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:k8s:upgrade", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "calls db:migrate" do
    expect(Rake::Task["db:migrate"]).to receive(:invoke)
    expect(Rake::Task["decidim:repair:url_in_content"]).to receive(:invoke)
    expect(Rake::Task["decidim:repair:translations"]).to receive(:invoke)

    task.execute
  end
end
