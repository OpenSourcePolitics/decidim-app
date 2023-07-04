# frozen_string_literal: true

require "spec_helper"

describe "rake k8s:export_configuration", type: :task do
  let(:image) { "dummy-image" }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "invokes the configuration exporter" do
    with_modified_env IMAGE: image do
      expect(K8sConfigurationExporter).to receive(:export!).with(image).and_return(true)

      task.execute
    end
  end
end
