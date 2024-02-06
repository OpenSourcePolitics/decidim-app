# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:k8s:export_configuration", type: :task do
  let(:image) { "dummy-image" }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "invokes the configuration exporter" do
    with_modified_env IMAGE: image do
      expect(DecidimApp::K8s::ConfigurationExporter).to receive(:export!).with(image).at_least(:once).and_return(true)

      task.execute
    end
  end
end
