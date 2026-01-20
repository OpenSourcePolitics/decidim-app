# frozen_string_literal: true

require "spec_helper"

describe "Organization scopes" do
  include Decidim::SanitizeHelper

  let(:organization) { create(:organization, default_locale: :en, available_locales: [:en, :es, :ca, :fr]) }
  let(:admin) { create(:user, :admin, :confirmed, organization:) }
  let!(:attributes) { attributes_for(:scope) }

  before do
    switch_to_host(organization.host)
  end

  describe "Managing scopes" do
    let!(:scope_type) { create(:scope_type, organization: admin.organization) }

    before do
      login_as admin, scope: :user
      visit decidim_admin.root_path
      click_link_or_button "Settings"
      click_link_or_button "Scopes"
    end

    it "can create new scopes" do
      click_link_or_button "Add"

      within ".new_scope" do
        fill_in_i18n :scope_name, "#scope-name-tabs", **attributes[:name].except("machine_translations")
        fill_in "Code", with: "MY-DISTRICT"
        select scope_type.name["en"], from: :scope_scope_type_id

        find("*[type=submit]").click
      end

      expect(page).to have_admin_callout("successfully")

      within ".draggable-list" do
        expect(page).to have_content(translated(attributes[:name]))
      end

      visit decidim_admin.root_path
      expect(page).to have_content("created the #{translated(attributes[:name])} scope")
    end

    context "with existing scopes" do
      let!(:scope) { create(:scope, organization:) }

      before do
        visit current_path
      end

      it "can edit them" do
        within ".draggable-content", text: translated(scope.name) do
          click_link_or_button "Edit"
        end

        within ".edit_scope" do
          fill_in_i18n :scope_name, "#scope-name-tabs", **attributes[:name].except("machine_translations")
          find("*[type=submit]").click
        end

        expect(page).to have_admin_callout("successfully")

        within ".draggable-list" do
          expect(page).to have_content(translated(attributes[:name]))
        end

        visit decidim_admin.root_path
        expect(page).to have_content("updated the #{translated(attributes[:name])} scope")
      end

      it "can delete them" do
        within ".draggable-content", text: translated(scope.name) do
          accept_confirm { click_link_or_button "Destroy" }
        end

        expect(page).to have_admin_callout("successfully")

        within ".card-section" do
          expect(page).to have_no_content(translated(scope.name))
        end
      end

      it "can create a new subcope" do
        within ".draggable-content", text: translated(scope.name) do
          find("a", text: translated(scope.name)).click
        end

        click_link_or_button "Add"

        within ".new_scope" do
          fill_in_i18n :scope_name, "#scope-name-tabs", en: "My nice subdistrict",
                                                        es: "Mi lindo subdistrito",
                                                        ca: "El meu bonic subbarri"
          fill_in "Code", with: "MY-SUBDISTRICT"
          select scope_type.name["en"], from: :scope_scope_type_id

          find("*[type=submit]").click
        end

        expect(page).to have_admin_callout("successfully")

        within ".draggable-list" do
          expect(page).to have_content("My nice subdistrict")
        end
      end
    end
  end
end
