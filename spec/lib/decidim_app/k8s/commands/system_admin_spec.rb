# frozen_string_literal: true

require "spec_helper"

require "decidim-app/k8s/commands/system_admin"

describe DecidimApp::K8s::Commands::SystemAdmin do
  subject { described_class.new(default_system_admin_configuration) }

  let(:default_system_admin_configuration) do
    {
      email: "system@example.org",
      password: "password123456"
    }
  end

  describe "run" do
    it "creates the system admin" do
      expect do
        expect(subject.run).to be_a(Decidim::System::Admin)
      end.to change(Decidim::System::Admin, :count).by(1)
    end

    context "when system admin already exists" do
      let!(:system_admin) { create(:admin, email: default_system_admin_configuration[:email]) }

      it "updates the system admin" do
        expect do
          expect(subject.run).to be_a(Decidim::System::Admin)
        end.not_to change(Decidim::System::Admin, :count)
      end
    end
  end
end
