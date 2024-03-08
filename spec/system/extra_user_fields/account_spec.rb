# frozen_string_literal: true

require "spec_helper"

describe "Account", type: :system do
  shared_examples_for "does not display extra user field" do |field, label|
    it "does not display field '#{field}'" do
      expect(page).not_to have_content(label)
    end
  end

  let(:organization) { create(:organization, extra_user_fields: extra_user_fields) }
  let(:user) { create(:user, :confirmed, organization: organization, password: password, password_confirmation: password) }
  let(:password) { "dqCFgjfDbC7dPbrv" }
  # rubocop:disable Style/TrailingCommaInHashLiteral
  let(:extra_user_fields) do
    {
      "enabled" => true,
      "date_of_birth" => date_of_birth,
      "postal_code" => postal_code,
      "gender" => gender,
      "country" => country,
      "phone_number" => phone_number,
      "location" => location,
      # Block ExtraUserFields ExtraUserFields

      # EndBlock
    }
  end
  # rubocop:enable Style/TrailingCommaInHashLiteral

  let(:date_of_birth) do
    { "enabled" => true }
  end

  let(:postal_code) do
    { "enabled" => true }
  end

  let(:country) do
    { "enabled" => true }
  end

  let(:gender) do
    { "enabled" => true }
  end

  let(:phone_number) do
    { "enabled" => true }
  end

  let(:location) do
    { "enabled" => true }
  end

  # Block ExtraUserFields RspecVar

  # EndBlock

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when on the account page" do
    before do
      visit decidim.account_path
    end

    describe "updating personal data" do
      it "updates the user's data" do
        within "form.edit_user" do
          select "Castellano", from: :user_locale
          fill_in :user_name, with: "Nikola Tesla"
          fill_in :user_personal_url, with: "https://example.org"
          fill_in :user_about, with: "A Serbian-American inventor, electrical engineer, mechanical engineer, physicist, and futurist."

          fill_in :user_date_of_birth, with: "01/01/2000"
          select "Other", from: :user_gender
          select "Argentina", from: :user_country
          fill_in :user_postal_code, with: "00000"
          fill_in :user_phone_number, with: "0123456789"
          fill_in :user_location, with: "Cahors"
          # Block ExtraUserFields FillFieldSpec

          # EndBlock

          find("*[type=submit]").click
        end

        within_flash_messages do
          expect(page).to have_content("successfully")
        end

        within ".title-bar" do
          expect(page).to have_content("Nikola Tesla")
        end
      end
    end

    context "when date_of_birth is not enabled" do
      let(:date_of_birth) do
        { "enabled" => false }
      end

      it_behaves_like "does not display extra user field", "date_of_birth", "Date of birth"
    end

    context "when postal_code is not enabled" do
      let(:postal_code) do
        { "enabled" => false }
      end

      it_behaves_like "does not display extra user field", "postal_code", "Postal code"
    end

    context "when country is not enabled" do
      let(:country) do
        { "enabled" => false }
      end

      it_behaves_like "does not display extra user field", "country", "Country"
    end

    context "when gender is not enabled" do
      let(:gender) do
        { "enabled" => false }
      end

      it_behaves_like "does not display extra user field", "gender", "Gender"
    end

    context "when phone number is not enabled" do
      let(:phone_number) do
        { "enabled" => false }
      end

      it_behaves_like "does not display extra user field", "phone number", "Phone number"
    end

    context "when location is not enabled" do
      let(:location) do
        { "enabled" => false }
      end

      it_behaves_like "does not display extra user field", "location", "Location"
    end
  end
end
