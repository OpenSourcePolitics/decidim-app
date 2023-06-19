# frozen_string_literal: true

require "spec_helper"

describe "rake k8s:export_configuration", type: :task do
  let(:image) { "dummy-image" }
  let(:enable_sync) { true }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "invokes the configuration exporter" do
    with_modified_env IMAGE: image, ENABLE_SYNC: enable_sync.to_s do
      expect(K8sConfigurationExporter).to receive(:export!).with(image, enable_sync).and_return(true)

      task.execute
    end
  end
end
