# frozen_string_literal: true

shared_examples "on/off invitation nickname" do
  context "when hide nickname is active" do
    it "hides nickname and user can register" do
      visit last_email_link

      within ".new_user" do
        expect(page).not_to have_field("invitation_user_nickname")

        fill_in :invitation_user_password, with: "pNY6h9crVtVHZbdE"
        check :invitation_user_tos_agreement
        check :user_newsletter_notifications

        find("*[type=submit]").click
      end

      expect(page).to have_content("Your password was set successfully")

      expect(Decidim::User.last).to be_valid_password("pNY6h9crVtVHZbdE")
    end
  end

  context "when hide nickname is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:hide_nickname).and_return(false)
    end

    it "shows nickname and user can register" do
      visit last_email_link

      within ".new_user" do
        expect(page).to have_field("invitation_user_nickname")
        fill_in :invitation_user_password, with: "pNY6h9crVtVHZbdE"
        check :invitation_user_tos_agreement
        check :user_newsletter_notifications

        find("*[type=submit]").click
      end

      expect(page).to have_content("Your password was set successfully")

      expect(Decidim::User.last).to be_valid_password("pNY6h9crVtVHZbdE")
    end
  end
end

shared_examples "on/off invitation instant_validation on nickname" do
  let!(:existing) { create :user, :confirmed, organization: Decidim::Organization.last, nickname: "existing", avatar: nil }
  before do
    allow(Decidim::FriendlySignup).to receive(:hide_nickname).and_return(false)
  end

  context "when use_instant_validation is active" do
    it "hides nickname and user can register", :slow do
      visit last_email_link

      within ".new_user" do
        fill_in :invitation_user_nickname, with: "mynickname"
        fill_in :invitation_user_password, with: "mynickname12345"

        expect(page).to have_content("The password you have entered is too similar to your nickname")

        fill_in :invitation_user_nickname, with: "existing"
        expect(page).to have_content("Has already been taken")
      end
    end
  end

  context "when use_instant_validation is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:use_instant_validation).and_return(false)
    end

    it "shows nickname and user can register" do
      visit last_email_link

      within ".new_user" do
        fill_in :invitation_user_nickname, with: "mynickname"
        fill_in :invitation_user_password, with: "mynickname12345"
        sleep 0.3

        expect(page).not_to have_content("The password you have entered is too similar to your nickname")

        fill_in :invitation_user_nickname, with: ""
        sleep 0.3
        expect(page).to have_content("There's an error in this field.")
      end
    end
  end
end
