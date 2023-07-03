# frozen_string_literal: true

require "spec_helper"

require "decidim-app/k8s/commands/admin"

describe DecidimApp::K8s::Commands::Admin do
  subject { described_class.new(default_admin_configuration, organization) }

  let(:organization) { create(:organization) }
  let(:default_admin_configuration) do
    {
      "email" => "system@example.org",
      "password" => "password123456",
      "name" => "John Doe",
      "nickname" => "John"
    }
  end

  describe "run" do
    it "creates the system admin" do
      expect do
        expect(subject.run).to be_a(Decidim::User)
      end.to change(Decidim::User, :count).by(1)
    end

    context "when system admin already exists" do
      let!(:system_admin) { create(:user, email: default_admin_configuration["email"], organization: organization) }

      it "updates the system admin" do
        expect do
          expect(subject.run).to be_a(Decidim::User)
        end.not_to change(Decidim::User, :count)
      end
    end
  end
end
