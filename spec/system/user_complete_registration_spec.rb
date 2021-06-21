# frozen_string_literal: true

require "spec_helper"

describe "User complete registration", type: :system do
  let(:user) { create(:user) }
  let(:organization) { user.organization }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when visiting complete registration form" do
    before do
      visit decidim.user_complete_registration_path
    end

    describe "skipping this step" do
      it "redirects the user without updating any data" do
        click_link "Skip this step"

        expect(page).to have_current_path decidim.root_path
      end
    end

    describe "updating personal data" do
      it "updates the user's data" do
        within "form.edit_user" do
          expect(page).to have_content("Select your interests")
          expect(page).to have_content("My interests")
          find("*[type=submit]").click
        end

        within_flash_messages do
          expect(page).to have_content("successfully")
        end
      end
    end
  end
end
