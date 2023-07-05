# frozen_string_literal: true

require "spec_helper"

require "decidim_app/k8s/commands/admin"

describe DecidimApp::K8s::Commands::Admin do
  subject { described_class.new(default_admin_configuration, organization) }

  let!(:admin) { create(:user, email: default_admin_configuration[:email], name: "Jane Doe", organization: organization) }

  let(:organization) { create(:organization) }
  let(:name) { "John Doe" }
  let(:default_admin_configuration) do
    {
      email: "system@example.org",
      password: "password123456",
      name: name,
      nickname: "John"
    }
  end

  describe "#run" do
    it "updates the admin" do
      expect do
        expect(subject.run).to be_a(Decidim::User)
      end.not_to change(Decidim::User, :count)

      expect(admin.reload.name).to eq(default_admin_configuration[:name])
    end

    context "when admin is invalid" do
      let(:name) { nil }

      it "raises an error" do
        expect { subject.run }.to raise_error(RuntimeError, "Admin user #{default_admin_configuration[:nickname]} could not be updated")
      end
    end
  end

  describe ".run" do
    it "runs the installation" do
      # rubocop:disable RSpec/AnyInstance
      expect_any_instance_of(described_class).to receive(:run).once
      # rubocop:enable RSpec/AnyInstance

      described_class.run(default_admin_configuration, organization)
    end
  end
end
