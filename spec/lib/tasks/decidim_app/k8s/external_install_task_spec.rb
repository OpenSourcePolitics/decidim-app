# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:k8s:external_install", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "calls db:migrate" do
    with_modified_env path: "dummy_path" do
      expect(DecidimApp::K8s::Manager).to receive(:install).with("dummy_path")

      task.execute
    end
  end
end
