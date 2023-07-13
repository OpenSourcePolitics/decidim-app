# frozen_string_literal: true

shared_examples "on/off invitation passwords" do
  describe "Accept an invitation" do
    it "asks for a password and redirects to the organization dashboard" do
      visit last_email_link

      within "form.new_user" do
        expect(page).not_to have_selector "#invitation_user_password_confirmation"

        fill_in :invitation_user_password, with: "decidim123456789"
        check :invitation_user_tos_agreement
        find("*[type=submit]").click
      end

      expect(page).to have_selector ".callout--full"

      within ".callout--full" do
        page.find(".close-button").click
      end

      expect(page).to have_content("Dashboard")
      expect(page).to have_current_path "/admin/"
    end
  end

  context "when override_passwords is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:override_passwords).and_return(false)
    end

    it "asks for a password and redirects to the organization dashboard" do
      visit last_email_link

      within "form.new_user" do
        expect(page).to have_selector "#invitation_user_password_confirmation"

        fill_in :invitation_user_password, with: "decidim123456789"
        check :invitation_user_tos_agreement
        find("*[type=submit]").click

        expect(page).to have_content("doesn't match Password")

        fill_in :invitation_user_password, with: "decidim123456789"
        fill_in :invitation_user_password_confirmation, with: "decidim123456789"
        find("*[type=submit]").click
      end

      expect(page).to have_selector ".callout--full"

      within ".callout--full" do
        page.find(".close-button").click
      end

      expect(page).to have_content("Dashboard")
      expect(page).to have_current_path "/admin/"
    end
  end
end

shared_examples "on/off invitation instant_validation" do
  context "when instant_validation is active" do
    it "shows custom validation" do
      visit last_email_link

      within ".new_user" do
        expect(page).not_to have_field("invitation_user_password_confirmation")

        fill_in :invitation_user_password, with: "password11"
        sleep 0.3

        expect(page).to have_css(".form-error")
        expect(page).to have_content("The password you have entered is very common - we suggest using a different password")

        fill_in :invitation_user_password, with: "short"
        sleep 0.3

        expect(page).to have_content("The password you have entered is too short")
      end
    end
  end

  context "when instant_validation is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:use_instant_validation).and_return(false)
    end

    it "does not show custom validation" do
      visit last_email_link

      within ".new_user" do
        fill_in :invitation_user_password, with: "short"
        sleep 0.3

        expect(page).to have_css(".form-error")
        expect(page).to have_content("The password is too short")
      end
    end
  end
end
