# frozen_string_literal: true

require "spec_helper"

describe "Mobile header" do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

  context "when user visits with a desktop browser" do
    before do
      switch_to_host(organization.host)
      visit decidim.root_path
    end

    it "does not include mobile login classes" do
      expect(page).to have_no_css(".main-bar__links-mobile__login")
    end

    it "does not include a dropdown menu" do
      expect(page).to have_no_css("#main-dropdown-summary-mobile")
    end
  end

  context "when user visit a mobile browser" do
    before do
      driven_by(:iphone)
      switch_to_host(organization.host)
      visit decidim.root_path
      click_on(id: "dc-dialog-accept")
    end

    it "has a sticky header" do
      expect(page).to have_css("#sticky-header-container")
    end

    context "when user view the header" do
      context "and organization has a favicon without logo" do
        it "has a favicon as the logo" do
          expect(page).to have_css(".main-bar__logo")
          within ".main-bar__logo-mobile" do
            expect(page.find("img")["src"]).to have_content("icon.png")
          end
        end
      end

      context "and organization has a logo" do
        let!(:organization) { create(:organization, logo: Decidim::Dev.test_file("city.jpeg", "image/jpeg")) }

        it "displays the logo" do
          expect(page).to have_css(".main-bar__logo")
          within ".main-bar__logo-mobile" do
            expect(page.find("img")["src"]).to have_content("city.jpeg")
          end
        end
      end

      it "includes a clearly visible login access" do
        expect(page).to have_css(".main-bar__links-mobile__login")
      end
    end

    context "when user access to the hamburger menu" do
      before do
        click_on(id: "main-dropdown-summary-mobile")
      end

      it "includes access to the language selector and search bar" do
        within ".menu-bar__main-dropdown__top" do
          expect(page).to have_css(".filter-search")
          expect(page).to have_css("#dropdown-trigger-language-chooser-mobile")
        end
      end
    end
  end

  context "when user is logged in" do
    before do
      driven_by(:iphone)
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim.root_path
      click_on(id: "dc-dialog-accept")
    end

    it "displays an avatar on the header" do
      expect(page).to have_css(".main-bar__avatar")
      expect(page).to have_css("#admin-bar")
      within ".main-bar__avatar" do
        expect(page.find("img")["alt"]).to have_content("Avatar: avatar")
      end
    end
  end
end
