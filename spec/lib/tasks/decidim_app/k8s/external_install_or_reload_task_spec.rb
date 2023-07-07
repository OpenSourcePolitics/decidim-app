# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:k8s:external_install_or_reload", type: :task do
  let(:path) { Rails.root.join("spec/fixtures/k8s_configuration_example.yml") }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "calls the manager service" do
    with_modified_env path: path.to_s do
      expect(DecidimApp::K8s::Manager).to receive(:run).with(path.to_s)

      task.execute
    end
  end

  context "when path is not specified" do
    it "raises an error" do
      with_modified_env path: nil do
        expect { task.execute }.to raise_error "You must specify a path to an external install configuration, path='path/to/external_install_configuration.yml'"
      end
    end
  end

  context "when path is specified but file does not exist" do
    it "raises an error" do
      with_modified_env path: "dummy_path" do
        expect { task.execute }.to raise_error "You must specify a path to an external install configuration, path='path/to/external_install_configuration.yml'"
      end
    end
  end
end
