# frozen_string_literal: true

shared_examples "on/off account passwords" do
  context "when override_passwords is active" do
    before do
      visit decidim.account_path
    end

    it "updates the password successfully" do
      within "form.edit_user" do
        page.find(".change-password").click

        fill_in :user_password, with: "sekritpass123"

        find("*[type=submit]").click
      end

      within_flash_messages do
        expect(page).to have_content("successfully")
      end

      expect(user.reload.valid_password?("sekritpass123")).to be(true)
    end
  end

  context "when override_passwords is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:override_passwords).and_return(false)
      visit decidim.account_path
    end

    it "does not updates the password if confirmation is not filled" do
      within "form.edit_user" do
        page.find(".change-password").click

        fill_in :user_password, with: "sekritpass123"
        find("*[type=submit]").click
      end

      within "#passwordChange" do
        expect(page).to have_content("There's an error in this field.")
      end
    end

    it "updates the password successfully" do
      within "form.edit_user" do
        page.find(".change-password").click

        fill_in :user_password, with: "sekritpass123"
        fill_in :user_password_confirmation, with: "sekritpass123"
        find("*[type=submit]").click
      end

      within_flash_messages do
        expect(page).to have_content("successfully")
      end

      expect(user.reload.valid_password?("sekritpass123")).to be(true)
    end
  end
end
