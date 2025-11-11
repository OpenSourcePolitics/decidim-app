# frozen_string_literal: true

require "spec_helper"

describe "Omniauth Publik", type: :system do
  let(:organization) { create(:organization) }

  before do
    switch_to_host(organization.host)
    visit decidim.root_path
  end

  context "when using Publik" do
    let(:omniauth_hash) do
      OmniAuth::AuthHash.new(
        provider: "publik",
        uid: "123545",
        info: {
          nickname: "foobar",
          name: "Foo Bar",
          email: "foo@bar.com"
        }
      )
    end

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:publik] = omniauth_hash
      OmniAuth.config.add_camelization "publik", "Publik"
      OmniAuth.config.request_validation_phase = ->(env) {} if OmniAuth.config.respond_to?(:request_validation_phase)
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:publik] = nil
      OmniAuth.config.camelizations.delete("publik")
    end

    context "when the user does not exist yet" do
      it "creates a new User and completes the registration form" do
        find(".sign-up-link").click
        click_link "Sign in with Publik"

        expect(page).to have_content("Complete your profile")

        select "2000", from: "user_birth_date_1i"
        select "January", from: "user_birth_date_2i"
        select "15", from: "user_birth_date_3i"

        fill_in "user_address", with: "123 Rue de la Paix"
        fill_in "user_postal_code", with: "75001"
        fill_in "user_city", with: "Paris"

        check "user_certification"
        check "user_tos_agreement"

        within "form.new_user" do
          find("*[type=submit]").click
        end

        expect(page).to have_content("Successfully")
        expect_user_logged
      end
    end

    context "when the user already exists with confirmed email" do
      let!(:existing_user) do
        create(:user,
               email: "foo@bar.com",
               organization: organization,
               confirmed_at: Time.current)
      end

      it "signs in the existing user and creates the identity" do
        find(".sign-up-link").click
        click_link "Sign in with Publik"

        expect(page).to have_content("Successfully")
        expect_user_logged

        identity = existing_user.identities.find_by(provider: "publik", uid: "123545")
        expect(identity).to be_present
        expect(identity.organization).to eq(organization)
      end
    end

    context "when the user already exists but is not confirmed" do
      let!(:existing_user) do
        create(:user,
               email: "foo@bar.com",
               organization: organization,
               confirmed_at: nil)
      end

      it "confirms the user and signs them in" do
        find(".sign-up-link").click
        click_link "Sign in with Publik"

        expect(page).to have_content("Successfully")
        expect_user_logged

        existing_user.reload
        expect(existing_user.confirmed?).to be true

        identity = existing_user.identities.find_by(provider: "publik", uid: "123545")
        expect(identity).to be_present
      end
    end

    context "when the user already exists but is blocked" do
      let!(:existing_user) do
        create(:user,
               email: "foo@bar.com",
               organization: organization,
               confirmed_at: Time.current,
               blocked: true,
               blocked_at: Time.current)
      end

      it "does not sign in the user and shows an error" do
        find(".sign-up-link").click
        click_link "Sign in with Publik"

        expect(page).to have_content("blocked")
        expect(page).not_to have_content("Successfully")
      end
    end
  end
end
