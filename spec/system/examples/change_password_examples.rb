# frozen_string_literal: true

shared_examples "on/off change passwords" do
  context "when override_passwords is active" do
    it "does not show password confirmation" do
      visit last_email_link

      within ".new_user" do
        expect(page).not_to have_field("password_user_password_confirmation")

        fill_in :password_user_password, with: "DfyvHn425mYAy2HL"
        find("*[type=submit]").click
      end

      expect(page).to have_content("Your password has been successfully changed")
      expect(page).to have_current_path "/"
    end
  end

  context "when override_passwords is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:override_passwords).and_return(false)
    end

    it "shows password confirmation" do
      visit last_email_link

      within ".new_user" do
        expect(page).to have_field("password_user_password_confirmation")

        fill_in :password_user_password, with: "DfyvHn425mYAy2HL"
        find("*[type=submit]").click
        expect(page).to have_content("doesn't match Password")

        fill_in :password_user_password, with: "DfyvHn425mYAy2HL"
        fill_in :password_user_password_confirmation, with: "DfyvHn425mYAy2HL"
        find("*[type=submit]").click
      end

      expect(page).to have_content("Your password has been successfully changed")
      expect(page).to have_current_path "/"
    end
  end

  context "when instant_validation is active" do
    it "shows custom validation" do
      visit last_email_link

      within ".new_user" do
        expect(page).not_to have_field("password_user_password_confirmation")

        fill_in :password_user_password, with: "password11"
        sleep 0.3

        expect(page).to have_css(".form-error")
        expect(page).to have_content("The password you have entered is very common - we suggest using a different password")

        fill_in :password_user_password, with: "short"
        sleep 0.3

        expect(page).to have_content("The password you have entered is too short")
      end
    end
  end

  context "when instant_validation is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:use_instant_validation).and_return(false)
    end

    it "shows custom validation" do
      visit last_email_link

      within ".new_user" do
        fill_in :password_user_password, with: "short"
        sleep 0.3

        expect(page).to have_css(".form-error")
        expect(page).to have_content("The password is too short")
      end
    end
  end
end
