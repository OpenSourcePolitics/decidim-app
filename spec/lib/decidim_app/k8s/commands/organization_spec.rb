# frozen_string_literal: true

require "spec_helper"

require "decidim_app/k8s/commands/organization"

describe DecidimApp::K8s::Commands::Organization do
  subject { described_class.new(organization_configuration, default_admin_configuration) }

  let(:reference_prefix) { "JKR" }
  let(:users_registration_mode) { "enabled" }
  let(:secondary_hosts) { %w(osp.example.org osp.decidim.example) }
  let(:organization_configuration) do
    {
      name: "OSP Decidim",
      host: "decidim.example.org",
      secondary_hosts: secondary_hosts.join("\n"),
      available_locales: %w(en fr),
      default_locale: "fr",
      reference_prefix: reference_prefix,
      users_registration_mode: users_registration_mode,
      file_upload_settings: {
        allowed_file_extensions: {
          admin: "dummy,foo,bar",
          image: "dummy,foo,bar",
          default: "dummy,foo,bar"
        },
        allowed_content_types: {
          admin: "dummy/*",
          default: "dummy/*"
        },
        maximum_file_size: {
          avatar: 3,
          default: 9
        }
      },
      smtp_settings: {
        from: "OSP Decidim",
        from_email: "ne-pas-repondre@example.org",
        from_label: "OSP Decidim",
        user_name: "example",
        password: "password",
        address: "address.smtp.org",
        port: 8080,
        authentication: "plain",
        enable_starttls_auto: true
      },
      omniauth_settings: {
        publik: {
          enabled: "true",
          client_id: "12345",
          client_secret: "12345",
          site_url: "https://example.com/"
        }
      }
    }
  end

  let(:default_admin_configuration) do
    {
      name: "Admin user",
      email: "admin@example.org",
      password: "password123456"
    }
  end

  describe "#call" do
    it "creates the organization" do
      listener = double("Listener")
      subject.subscribe(listener)
      allow(listener).to receive(:ok)

      expect do
        expect { subject.call }.to broadcast(:ok)
      end.to change(Decidim::Organization, :count).by(1).and change(Decidim::User, :count).by(1)

      organization = Decidim::Organization.last.reload

      expect(listener).to have_received(:ok).with(
        {
          organization: {
            created: {
              status: :ok,
              messages: []
            },
            updated: {
              status: :ok,
              messages: []
            }
          }
        },
        organization
      )

      expect(organization.name).to eq(organization_configuration[:name])
      expect(organization.host).to eq(organization_configuration[:host])
      expect(organization.secondary_hosts).to eq(secondary_hosts)
      expect(organization.available_locales).to eq(organization_configuration[:available_locales])
      expect(organization.default_locale).to eq(organization_configuration[:default_locale])
      expect(organization.reference_prefix).to eq(organization_configuration[:reference_prefix])
      expect(organization.users_registration_mode).to eq(organization_configuration[:users_registration_mode])
    end

    context "when organization is invalid" do
      let(:users_registration_mode) { "invalid" }

      it "broadcasts invalid" do
        listener = double("Listener")
        expect(listener).to receive(:invalid).with(
          {
            organization: {
              created: {
                status: :invalid,
                messages: {
                  users_registration_mode: [
                    "is not included in the list"
                  ]
                }
              }
            }
          },
          nil
        )
        subject.subscribe(listener)

        expect do
          expect { subject.call }.to broadcast(:invalid)
        end.not_to change(Decidim::Organization, :count)
      end
    end

    context "when organization already exists" do
      let!(:organization) { create(:organization, host: organization_configuration[:host], users_registration_mode: :disabled) }

      it "updates the organization" do
        listener = double("Listener")
        expect(listener).to receive(:ok).with(
          {
            organization: {
              updated: {
                status: :ok,
                messages: []
              }
            }
          },
          organization.reload
        )
        subject.subscribe(listener)

        expect do
          expect(subject.call).to be_a(::Rectify::Command)
        end.to not_change(Decidim::Organization, :count)
      end

      it "does not update the Decidim::User" do
        listener = double("Listener")
        expect(listener).to receive(:ok).with(
          {
            organization: {
              updated: {
                status: :ok,
                messages: []
              }
            }
          },
          organization.reload
        )
        subject.subscribe(listener)

        expect do
          expect { subject.call }.to broadcast(:ok)
        end.to not_change(Decidim::User, :count)
      end

      describe "organization attributes" do
        before do
          subject.call
        end

        it "updates organization attributes" do
          expect(organization.reload.users_registration_mode).to eq(organization_configuration[:users_registration_mode])
          expect(organization.reload.name).to eq(organization_configuration[:name])
          expect(organization.reload.host).to eq(organization_configuration[:host])
          expect(organization.reload.secondary_hosts).to eq(secondary_hosts)
          expect(organization.reload.users_registration_mode).to eq(organization_configuration[:users_registration_mode])
        end

        it "updates the file_upload_settings" do
          file_upload_settings = organization.reload.file_upload_settings
          expect(file_upload_settings.keys).to match_array(%w(allowed_file_extensions allowed_content_types maximum_file_size))

          allowed_file_extensions = file_upload_settings["allowed_file_extensions"]
          expect(allowed_file_extensions.keys).to match_array(%w(admin image default))
          expect(allowed_file_extensions["admin"]).to match_array(%w(dummy foo bar))
          expect(allowed_file_extensions["image"]).to match_array(%w(dummy foo bar))
          expect(allowed_file_extensions["default"]).to match_array(%w(dummy foo bar))

          expect(file_upload_settings["allowed_content_types"].keys).to match_array(%w(admin default))
          allowed_content_types = file_upload_settings["allowed_content_types"]
          expect(allowed_content_types["admin"]).to match_array(["dummy/*"])
          expect(allowed_content_types["default"]).to match_array(["dummy/*"])

          expect(file_upload_settings["maximum_file_size"].keys).to match_array(%w(avatar default))
          maximum_file_size = file_upload_settings["maximum_file_size"]
          expect(maximum_file_size["avatar"]).to eq(3)
          expect(maximum_file_size["default"]).to eq(9)
        end

        it "updates the smtp_settings" do
          smtp_settings = organization.reload.smtp_settings
          expect(smtp_settings.keys).to match_array(%w(from from_email from_label user_name address port authentication enable_starttls_auto encrypted_password))
          expect(smtp_settings["from"]).to eq("OSP Decidim <ne-pas-repondre@example.org>")
          expect(smtp_settings["from_email"]).to eq("ne-pas-repondre@example.org")
          expect(smtp_settings["from_label"]).to eq("OSP Decidim")
          expect(smtp_settings["user_name"]).to eq("example")
          expect(smtp_settings["address"]).to eq("address.smtp.org")
          expect(smtp_settings["port"]).to eq(8080)
          expect(smtp_settings["authentication"]).to eq("plain")
          expect(smtp_settings["enable_starttls_auto"]).to eq(true)
          expect(Decidim::AttributeEncryptor.decrypt(smtp_settings["encrypted_password"])).to eq("password")
        end

        it "updates the omniauth_settings" do
          omniauth_settings = organization.reload.omniauth_settings
          expect(omniauth_settings.keys).to match_array(%w(omniauth_settings_publik_client_id omniauth_settings_publik_client_secret omniauth_settings_publik_site_url omniauth_settings_publik_enabled))
          expect(Decidim::AttributeEncryptor.decrypt(omniauth_settings["omniauth_settings_publik_client_id"])).to eq("12345")
          expect(Decidim::AttributeEncryptor.decrypt(omniauth_settings["omniauth_settings_publik_client_secret"])).to eq("12345")
          expect(Decidim::AttributeEncryptor.decrypt(omniauth_settings["omniauth_settings_publik_site_url"])).to eq("https://example.com/")
          expect(omniauth_settings["omniauth_settings_publik_enabled"]).to eq(true)
        end
      end

      context "when organization is invalid" do
        let(:users_registration_mode) { "invalid" }

        it "broadcasts invalid" do
          listener = double("Listener")
          expect(listener).to receive(:invalid).with(
            {
              organization: {
                updated: {
                  status: :invalid,
                  messages: {
                    users_registration_mode: [
                      "is not included in the list"
                    ]
                  }
                }
              }
            },
            nil
          )
          subject.subscribe(listener)

          expect do
            expect { subject.call }.to broadcast(:invalid)
          end.not_to change(Decidim::Organization, :count)
        end
      end
    end
  end
end
