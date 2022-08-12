# frozen_string_literal: true

shared_examples "on/off registration instant validation" do
  let!(:user) { create(:user, organization: organization, email: "bot@matrix.org", nickname: "agentsmith") }

  before do
    allow(Decidim::FriendlySignup).to receive(:hide_nickname).and_return(false)
    visit decidim.new_user_registration_path
  end

  context "when use_instant_validation is active" do
    it "Name is validated while writing" do
      within("#register-form") do
        expect(page).not_to have_content("Is invalid")

        fill_in "Your name", with: " "
        sleep 0.3 # wait for the delayed triggering fetcher

        expect(page).to have_content("Looks like you haven’t entered anything in this field")
      end
    end

    it "Email is validated while writing" do
      within("#register-form") do
        expect(page).not_to have_content("Is invalid")

        fill_in "Your email", with: " bot@matrix"
        sleep 0.3

        expect(page).to have_content("The email address looks incomplete")

        fill_in "Your email", with: "bot@matrix.org"
        sleep 0.3

        expect(page).to have_content("This email is already in use for another account. Try signing in or use another email")
      end
    end

    it "nickname is validated while writing" do
      within("#register-form") do
        expect(page).not_to have_content("Is invalid")

        fill_in "Nickname", with: "agentsmith"
        sleep 0.3

        expect(page).to have_content("Has already been taken")
      end
    end

    it "Password is validated while writing" do
      within("#register-form") do
        expect(page).not_to have_content("The password you have entered is too short")

        fill_in "Password", with: "mypas"
        sleep 0.3

        expect(page).to have_content("The password you have entered is too short")
      end
    end

    it "Password validates against dynamic content" do
      within("#register-form") do
        expect(page).not_to have_content("The password you have entered is too similar to your name")

        fill_in "Your name", with: "Agent Smith 1984"
        fill_in "Password", with: "agentsmith1984"
        sleep 0.3

        expect(page).to have_content("The password you have entered is too similar to your name")

        expect(page).not_to have_content("The password you have entered is very common - we suggest using a different password")

        fill_in "Password", with: "password11"
        sleep 0.3

        expect(page).to have_content("The password you have entered is very common - we suggest using a different password")
      end
    end
  end

  context "when use_instant_validation is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:use_instant_validation).and_return(false)
      visit decidim.new_user_registration_path
    end

    it "Email is ABIDE validated while writing" do
      within("#register-form") do
        expect(page).not_to have_content("There's an error in this field.")

        fill_in "Your email", with: " bot@matrix"
        sleep 0.3

        expect(page).not_to have_content("Is invalid")
        expect(page).to have_content("There's an error in this field.")
      end
    end

    it "Password is not validated while writing" do
      within("#register-form") do
        fill_in "Password", with: "mypas"
        sleep 0.3

        expect(page).not_to have_content("The password you have entered is too short")
      end
    end

    it "Password does not validate against dynamic content" do
      within("#register-form") do
        expect(page).not_to have_content("The password you have entered is too similar to your name")

        fill_in "Your name", with: "Agent Smith 1984"
        fill_in "Password", with: "agentsmith1984"
        sleep 0.3

        expect(page).not_to have_content("The password you have entered is too similar to your name")
        expect(page).not_to have_content("The password you have entered is very common - we suggest using a different password")

        fill_in "Password", with: "password11"
        sleep 0.3

        expect(page).not_to have_content("The password you have entered is too similar to your name")
        expect(page).not_to have_content("The password you have entered is very common - we suggest using a different password")
      end
    end
  end
end
