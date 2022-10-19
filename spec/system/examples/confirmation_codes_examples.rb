# frozen_string_literal: true

shared_examples "on/off confirmation codes" do
  context "when confirmation codes is active" do
    before do
      visit decidim_friendly_signup.confirmation_codes_path(confirmation_token: confirmation_token)
    end

    it "confirms the user" do
      expect(user.reload).not_to be_confirmed

      fill_confirmation_code(code)

      within_flash_messages do
        expect(page).to have_content("Your account has been succesfully confirmed")
      end

      expect(user.reload).to be_confirmed
    end

    context "when code is incorrect" do
      let(:code) { 1234 }

      it "does not confirm the user" do
        expect(user.reload).not_to be_confirmed

        fill_confirmation_code(code)

        within_flash_messages do
          expect(page).to have_content("Code is invalid")
        end

        expect(user.reload).not_to be_confirmed
      end
    end

    shared_examples "invalid token" do
      it "redirects the user out of here" do
        expect(page).to have_content("Log in")
        within_flash_messages do
          expect(page).to have_content("Invalid token")
        end
      end
    end

    context "when token is incorrect" do
      let(:confirmation_token) { "blabla" }

      it_behaves_like "invalid token"
    end

    context "when user is already confirmed" do
      let!(:user) { create(:user, :confirmed, organization: organization) }

      it_behaves_like "invalid token"
    end
  end

  context "when confirmation codes is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:use_confirmation_codes).and_return(false)
      visit decidim_friendly_signup.confirmation_codes_path(confirmation_token: confirmation_token)
    end

    it "redirects to standard confirmation" do
      expect(user.reload).not_to be_confirmed

      expect(page).to have_content("Resend confirmation instructions")

      expect(user.reload.confirmed?).to eq(false)
    end
  end
end

shared_examples "on/off standard confirmation" do
  context "when confirmation codes is active" do
    before do
      visit decidim.user_confirmation_path
    end

    it "sends the confirmation code" do
      expect(page).to have_content("Resend confirmation instructions")
      fill_email

      expect(page).to have_content("One last step...")
      within_flash_messages do
        expect(page).to have_content("A message with a code has been sent to your email address")
      end

      expect(user.reload.confirmed?).to eq(false)

      expect(last_email.subject).to include(code.to_s)
      expect(last_email.subject).to include(organization.name)
      expect(last_email_code).to eq(code.to_s)
      fill_confirmation_code(last_email_code)

      expect(user.reload).to be_confirmed
    end
  end

  context "when confirmation codes is not active" do
    before do
      allow(Decidim::FriendlySignup).to receive(:use_confirmation_codes).and_return(false)
      visit decidim.user_confirmation_path
    end

    it "sends standard confirmation" do
      clear_emails

      expect(page).to have_content("Resend confirmation instructions")
      fill_email

      expect(page).to have_content("Log in")
      within_flash_messages do
        expect(page).to have_content("If your email address exists in our database, you will receive an email with instructions")
      end

      perform_enqueued_jobs
      visit last_email_link
      expect(page).to have_content("Your email address has been successfully confirmed")
      expect(user.reload).to be_confirmed
    end
  end
end
