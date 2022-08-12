# frozen_string_literal: true

shared_examples "on/off sign in passwords" do
  context "when override_passwords is active" do
    before do
      visit decidim.new_user_session_path
    end

    it "There is a show password button" do
      expect(page).to have_field("session_user_password")
      expect(page).not_to have_field("session_user_password_confirmation")
      expect(page).to have_css(".user-password")
      expect(page).to have_css(".user-password title", visible: :hidden, text: "Show password")
    end
  end

  context "when override_passwords is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:override_passwords).and_return(false)
      visit decidim.new_user_session_path
    end

    it "There is a show password button" do
      expect(page).to have_field("session_user_password")
      expect(page).not_to have_field("session_user_password_confirmation")
      expect(page).not_to have_css(".user-password")
    end
  end
end
