# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:k8s:dump_db", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "invokes the configuration exporter" do
    expect(DecidimApp::K8s::ConfigurationExporter).to receive(:dump_db).at_least(:once).and_return(true)

    task.execute
  end
end
