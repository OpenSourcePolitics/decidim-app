# frozen_string_literal: true

require "spec_helper"

require "decidim-app/k8s/commands/admin"

describe DecidimApp::K8s::Commands::Admin do
  subject { described_class.new(default_admin_configuration, organization) }

  let!(:admin) { create(:user, email: default_admin_configuration[:email], name: "Jane Doe", organization: organization) }

  let(:organization) { create(:organization) }
  let(:default_admin_configuration) do
    {
      email: "system@example.org",
      password: "password123456",
      name: "John Doe",
      nickname: "John"
    }
  end

  describe "run" do
    it "updates the admin" do
      expect do
        expect(subject.run).to be_a(Decidim::User)
      end.not_to change(Decidim::User, :count)

      expect(admin.reload.name).to eq(default_admin_configuration[:name])
    end
  end
end
