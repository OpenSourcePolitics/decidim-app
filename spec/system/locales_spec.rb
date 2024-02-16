# frozen_string_literal: true

require "spec_helper"

describe "Locales", type: :system do
  describe "switching locales" do
    let(:organization) { create(:organization, available_locales: %w(fr en), default_locale: "en") }
    let(:user) { create(:user, :confirmed, locale: "en", organization: organization) }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim.root_path
    end

    it "changes the locale to the chosen one" do
      within_language_menu do
        click_link "Français"
      end

      expect(page).to have_content("Accueil")
    end

    it "only shows the available locales" do
      within_language_menu do
        expect(page).to have_content("Français")
        expect(page).to have_content("English")
        expect(page).to have_no_content("Castellano")
      end
    end

    it "keeps the locale between pages" do
      within_language_menu do
        click_link "Français"
      end

      click_link "Accueil"

      expect(page).to have_content("Accueil")
    end

    context "when not authenticated" do
      let(:user) { nil }

      it "displays devise messages with the right locale when not authenticated" do
        within_language_menu do
          click_link "Français"
        end

        visit decidim_admin.root_path

        expect(page).to have_content("Vous devez vous identifier ou vous créer un compte avant de continuer")
      end
    end

    context "when authentication fails" do
      let(:user) { nil }

      it "displays devise messages with the right locale" do
        within_language_menu do
          click_link "Français"
        end

        find(".sign-in-link").click

        fill_in "session_user_email", with: "toto@example.org"
        fill_in "session_user_password", with: "toto"

        click_button "S'identifier"

        expect(page).to have_content("Email ou mot de passe invalide")
      end
    end

    context "with a signed in user" do
      let(:user) { create(:user, :confirmed, locale: "fr", organization: organization) }

      it "uses the user's locale" do
        # Make sure the user is authenticated
        expect(page).not_to have_content("Sign in")
        expect(page).not_to have_content("S'identifier")
        expect(page).to have_content("Accueil")
      end
    end
  end
end
