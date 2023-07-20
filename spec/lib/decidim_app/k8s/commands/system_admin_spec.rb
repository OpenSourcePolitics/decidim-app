# frozen_string_literal: true

require "spec_helper"

require "decidim_app/k8s/commands/system_admin"

describe DecidimApp::K8s::Commands::SystemAdmin do
  subject { described_class.new(default_system_admin_configuration) }

  let(:password) { "password123456" }
  let(:email) { "system@example.org" }
  let(:default_system_admin_configuration) do
    {
      email: email,
      password: password
    }
  end

  describe "#run" do
    it "creates the system admin" do
      expect do
        expect(subject.call).to be_a(::Rectify::Command)
      end.to change(Decidim::System::Admin, :count).by(1)
    end

    context "when system admin already exists" do
      let!(:system_admin) { create(:admin, email: default_system_admin_configuration[:email]) }

      it "updates the system admin" do
        expect do
          expect(subject.call).to be_a(::Rectify::Command)
        end.not_to change(Decidim::System::Admin, :count)
      end
    end

    context "when system admin is invalid" do
      let(:password) { nil }

      it "broadcasts invalid" do
        broadcast = subject.call

        expect(broadcast.status_registry).to eq({ system_admin: {
                                                  updated: {
                                                    status: :invalid,
                                                    messages: { password: ["can't be blank"] }
                                                  }
                                                } })
      end
    end
  end
end
