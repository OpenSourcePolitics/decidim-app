# frozen_string_literal: true

require "spec_helper"

require "decidim-app/k8s/manager"
require "decidim-app/k8s/commands/organization"

describe DecidimApp::K8s::Manager do
  subject { described_class.new(configuration_path) }

  let(:configuration_path) { "spec/fixtures/k8s_configuration_example.yml" }
  let(:organization_configuration) { YAML.safe_load(File.read(configuration_path))["organizations"].first }
  let(:default_admin_configuration) { YAML.safe_load(File.read(configuration_path))["default_admin"] }

  describe "run" do
    it "runs the installation" do
      expect(DecidimApp::K8s::Commands::Organization).to receive(:run).twice

      subject.run
    end
  end
end
