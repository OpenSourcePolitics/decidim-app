# frozen_string_literal: true

require "spec_helper"

require "decidim_app/k8s/commands/organization"

describe DecidimApp::K8s::Commands::Organization do
  subject { described_class.new(organization_configuration, default_admin_configuration) }

  let(:reference_prefix) { "JKR" }
  let(:users_registration_mode) { "enabled" }
  let(:secondary_hosts) { %w[osp.example.org osp.decidim.example] }
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

  describe "#run" do
    it "creates the organization" do
      expect do
        expect(subject.run).to be_a(Decidim::Organization)
      end.to change(Decidim::Organization, :count).by(1).and change(Decidim::User, :count).by(1)

      organization = Decidim::Organization.last

      expect(organization.name).to eq(organization_configuration[:name])
      expect(organization.host).to eq(organization_configuration[:host])
      expect(organization.secondary_hosts).to eq(secondary_hosts)
      expect(organization.available_locales).to eq(organization_configuration[:available_locales])
      expect(organization.default_locale).to eq(organization_configuration[:default_locale])
      expect(organization.reference_prefix).to eq(organization_configuration[:reference_prefix])
      expect(organization.users_registration_mode).to eq(organization_configuration[:users_registration_mode])
    end

    context "when organization is invalid" do
      let(:reference_prefix) { nil }

      it "raises an error" do
        expect { subject.run }.to raise_error(RuntimeError, "Organization #{organization_configuration[:name]} could not be created")
      end
    end

    context "when organization already exists" do
      let!(:organization) { create(:organization, host: organization_configuration[:host], users_registration_mode: :disabled) }

      it "updates the organization" do
        expect do
          expect(subject.run).to be_a(Decidim::Organization)
        end.to not_change(Decidim::Organization, :count).and not_change(Decidim::User, :count)

        expect(organization.reload.users_registration_mode).to eq(organization_configuration[:users_registration_mode])
        expect(organization.reload.name).to eq(organization_configuration[:name])
        expect(organization.reload.host).to eq(organization_configuration[:host])
        expect(organization.reload.secondary_hosts).to eq(secondary_hosts)
        expect(organization.reload.users_registration_mode).to eq(organization_configuration[:users_registration_mode])

        file_upload_settings = organization.reload.file_upload_settings
        expect(file_upload_settings.keys).to match_array(%w(allowed_file_extensions allowed_content_types maximum_file_size))

        allowed_file_extensions = file_upload_settings["allowed_file_extensions"]
        expect(allowed_file_extensions.keys).to match_array(%w(admin image default))
        expect(allowed_file_extensions["admin"]).to match_array(["dummy", "foo", "bar"])
        expect(allowed_file_extensions["image"]).to match_array(["dummy", "foo", "bar"])
        expect(allowed_file_extensions["default"]).to match_array(["dummy", "foo", "bar"])

        expect(file_upload_settings["allowed_content_types"].keys).to match_array(%w(admin default))
        allowed_content_types = file_upload_settings["allowed_content_types"]
        expect(allowed_content_types["admin"]).to match_array(["dummy/*"])
        expect(allowed_content_types["default"]).to match_array(["dummy/*"])

        expect(file_upload_settings["maximum_file_size"].keys).to match_array(%w(avatar default))
        maximum_file_size = file_upload_settings["maximum_file_size"]
        expect(maximum_file_size["avatar"]).to eq(3)
        expect(maximum_file_size["default"]).to eq(9)

        smtp_settings = organization.reload.smtp_settings
        expect(smtp_settings.keys).to match_array(%w(from from_email from_label user_name password address port authentication enable_starttls_auto encrypted_password))
        expect(smtp_settings["from"]).to eq("OSP Decidim <ne-pas-repondre@example.org>")
        expect(smtp_settings["from_email"]).to eq("ne-pas-repondre@example.org")
        expect(smtp_settings["from_label"]).to eq("OSP Decidim")
        expect(smtp_settings["user_name"]).to eq("example")
        expect(smtp_settings["address"]).to eq("address.smtp.org")
        expect(smtp_settings["port"]).to eq(8080)
        expect(smtp_settings["authentication"]).to eq("plain")
        expect(smtp_settings["enable_starttls_auto"]).to eq(true)
      end

      context "when organization is invalid" do
        let(:users_registration_mode) { "invalid" }

        it "raises an error" do
          expect { subject.run }.to raise_error(RuntimeError, "Organization #{organization_configuration[:name]} could not be updated")
        end
      end
    end
  end

  describe ".run" do
    it "creates the organization" do
      # rubocop:disable RSpec/AnyInstance
      expect_any_instance_of(described_class).to receive(:run).once
      # rubocop:enable RSpec/AnyInstance

      described_class.run(organization_configuration, default_admin_configuration)
    end
  end
end
