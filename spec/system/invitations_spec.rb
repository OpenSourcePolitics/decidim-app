# frozen_string_literal: true

require "spec_helper"
require_relative "examples/invitation_password_examples"
require_relative "examples/invitation_nickname_examples"

describe "Admin invite", type: :system do
  let(:form) do
    Decidim::System::RegisterOrganizationForm.new(params)
  end

  let(:params) do
    {
      name: "Gotham City",
      reference_prefix: "JKR",
      host: "decide.lvh.me",
      organization_admin_name: "Fiorello Henry La Guardia",
      organization_admin_email: "f.laguardia@example.org",
      available_locales: ["en"],
      default_locale: "en",
      users_registration_mode: "enabled",
      file_upload_settings: Decidim::OrganizationSettings.default(:upload)
    }
  end

  before do
    expect do
      perform_enqueued_jobs { Decidim::System::RegisterOrganization.new(form).call }
    end.to broadcast(:ok)

    switch_to_host("decide.lvh.me")
  end

  it_behaves_like "on/off invitation passwords"

  it_behaves_like "on/off invitation instant_validation"

  it_behaves_like "on/off invitation nickname"

  it_behaves_like "on/off invitation instant_validation on nickname"
end
