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
      listener = double("Listener")
      subject.subscribe(listener)
      allow(listener).to receive(:ok)

      expect do
        expect { subject.call }.to broadcast(:ok)
      end.to change(Decidim::System::Admin, :count).by(1)

      expect(listener).to have_received(:ok).with(
        {
          system_admin: {
            updated: {
              status: :ok,
              messages: []
            }
          }
        },
        Decidim::System::Admin.last
      )
    end

    context "when system admin already exists" do
      let!(:system_admin) { create(:admin, email: default_system_admin_configuration[:email]) }

      it "updates the system admin" do
        listener = double("Listener")
        expect(listener).to receive(:ok).with(
          {
            system_admin: {
              updated: {
                status: :ok,
                messages: []
              }
            }
          },
          system_admin.reload
        )
        subject.subscribe(listener)

        expect do
          expect { subject.call }.to broadcast(:ok)
        end.not_to change(Decidim::System::Admin, :count)

        expect(system_admin.reload.email).to eq(default_system_admin_configuration[:email])
      end

      context "when system admin is invalid" do
        let(:password) { email }

        it "broadcasts invalid" do
          listener = double("Listener")
          expect(listener).to receive(:invalid).with(
            {
              system_admin: {
                updated: {
                  status: :invalid, messages: {
                    password: ["is too similar to your email"]
                  }
                }
              }
            },
            nil
          )
          subject.subscribe(listener)

          expect do
            expect { subject.call }.to broadcast(:invalid)
          end.not_to change(Decidim::System::Admin, :count)
        end
      end
    end
  end
end
