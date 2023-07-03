# frozen_string_literal: true

require "spec_helper"

require "decidim-app/k8s/manager"
require "decidim-app/k8s/commands/organization"
require "decidim-app/k8s/commands/system_admin"
require "decidim-app/k8s/commands/admin"

describe DecidimApp::K8s::Manager do
  subject { described_class.new(configuration_path) }

  let(:configuration_path) { "spec/fixtures/k8s_configuration_example.yml" }
  let(:organization_configuration) { YAML.safe_load(File.read(configuration_path))["organizations"].first }
  let(:default_admin_configuration) { YAML.safe_load(File.read(configuration_path))["default_admin"] }

  describe "run" do
    it "runs the installation" do
      expect(DecidimApp::K8s::Commands::SystemAdmin).to receive(:run).once
      expect(DecidimApp::K8s::Commands::Organization).to receive(:run).twice
      expect(DecidimApp::K8s::Commands::Admin).to receive(:run).twice

      subject.run
    end

    context "when configuration is invalid" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(DecidimApp::K8s::Configuration).to receive(:valid?).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it "raises runtime error" do
        expect { subject.run }.to raise_error(RuntimeError)
      end
    end
  end
end
