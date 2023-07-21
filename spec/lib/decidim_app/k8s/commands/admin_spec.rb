# frozen_string_literal: true

require "spec_helper"

require "decidim_app/k8s/commands/admin"

describe DecidimApp::K8s::Commands::Admin do
  subject { described_class.new(default_admin_configuration, organization) }

  let!(:admin) do
    create(:user,
           email: default_admin_configuration[:email],
           password: "excruciating_flaky_123456",
           name: "Jane Doe",
           organization: organization)
  end
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
      listener = double("Listener")
      expect(listener).to receive(:ok).with(
        {
          admin: {
            updated: {
              status: :ok,
              messages: []
            }
          }
        },
        admin.reload
      )
      subject.subscribe(listener)

      expect do
        expect { subject.call }.to broadcast(:ok)
      end.not_to change(Decidim::User, :count)

      expect(admin.reload.name).to eq(default_admin_configuration[:name])
    end

    context "when admin is invalid" do
      let(:name) { nil }

      it "broadcasts invalid" do
        listener = double("Listener")
        expect(listener).to receive(:invalid).with(
          {
            admin: {
              updated: {
                status: :invalid,
                messages: {
                  name: ["can't be blank"]
                }
              }
            }
          },
          nil
        )
        subject.subscribe(listener)

        expect do
          expect { subject.call }.to broadcast(:invalid)
        end.not_to change(Decidim::User, :count)
      end
    end
  end
end
