# frozen_string_literal: true

require "spec_helper"

require "decidim_app/k8s/commands/organization"

describe DecidimApp::K8s::Commands::Organization do
  subject { described_class.new(organization_configuration, default_admin_configuration) }

  let(:organization_configuration) do
    {
      name: "OSP Decidim",
      host: "decidim.osp.example",
      secondary_hosts: "osp.example.org,osp.decidim.example",
      available_locales: %w(en fr),
      default_locale: "fr",
      reference_prefix: "JKR",
      users_registration_mode: "enabled",
      file_upload_settings: {
        allowed_file_extensions: {
          admin: %w(jpeg jpg gif png bmp pdf doc docx xls xlsx ppt pptx ppx rtf txt odt ott odf otg ods ots),
          image: %w(jpg jpeg gif png bmp ico),
          default: %w(jpg jpeg gif png bmp pdf rtf txt)
        },
        allowed_content_types: {
          admin: %w(image/* application/vnd.oasis.opendocument application/vnd.ms-* application/msword application/vnd.ms-word application/vnd.openxmlformats-officedocument application/vnd.oasis.opendocument application/pdf application/rtf text/plain),
          default: %w(image/* application/pdf application/rtf text/plain)
        },
        maximum_file_size: {
          avatar: 5,
          default: 10
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

  describe "run" do
    it "creates the organization" do
      expect do
        expect(subject.run).to be_a(Decidim::Organization)
      end.to change(Decidim::Organization, :count).by(1).and change(Decidim::User, :count).by(1)
    end
  end

  context "when organization already exists" do
    let!(:organization) { create(:organization, host: organization_configuration[:host], users_registration_mode: :disabled) }

    it "updates the organization" do
      expect do
        expect(subject.run).to be_a(Decidim::Organization)
      end.to not_change(Decidim::Organization, :count).and not_change(Decidim::User, :count)

      expect(organization.reload.users_registration_mode).to eq(organization_configuration[:users_registration_mode])
    end
  end
end
