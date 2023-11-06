# frozen_string_literal: true

require "spec_helper"
require_relative "examples/confirmation_codes_examples"

def last_email_code
  Nokogiri::HTML(last_email_body).css("table.content .stat").first.text
end

def fill_confirmation_code(str)
  within ".card__content" do
    fill_in :"confirmation_numbers[0]", with: str.to_s[0]
    fill_in :"confirmation_numbers[1]", with: str.to_s[1]
    fill_in :"confirmation_numbers[2]", with: str.to_s[2]
    fill_in :"confirmation_numbers[3]", with: str.to_s[3]
  end
end

def fill_email
  within ".card__content" do
    fill_in :confirmation_user_email, with: email
    find("*[type=submit]").click
  end
end

def code_for(str)
  ::Decidim::FriendlySignup.confirmation_code(str)
end

describe "Registration", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:confirmation_token) { user.confirmation_token }
  let(:email) { user.email }
  let(:code) { code_for(confirmation_token) }

  before do
    allow(::Decidim::User).to receive(:confirm_within).and_return(10.minutes)
    switch_to_host(organization.host)
  end

  it_behaves_like "on/off confirmation codes"

  it_behaves_like "on/off standard confirmation"

  context "when token has expired" do
    before do
      # rubocop:disable Rails/SkipsModelValidations:
      user.update_column(:confirmation_sent_at, 11.minutes.ago)
      # rubocop:enable Rails/SkipsModelValidations:
      visit decidim_friendly_signup.confirmation_codes_path(confirmation_token: confirmation_token)
    end

    it "allows the user to generate a new confirmation code" do
      expect(page).to have_content("Resend confirmation instructions")

      within_flash_messages do
        expect(page).to have_content("this code has expired")
      end

      fill_email

      perform_enqueued_jobs

      expect(last_email_code).not_to eq(code.to_s)
      expect(last_email_code).to eq(code_for(user.reload.confirmation_token).to_s)
      fill_confirmation_code(last_email_code)

      expect(user.reload).to be_confirmed
    end
  end

  context "when post request gets attacked" do
    let(:code) { 1234 }
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      DecidimApp::RackAttack.enable_rack_attack!
      DecidimApp::RackAttack.apply_configuration
      Rack::Attack.reset!

      visit decidim_friendly_signup.confirmation_codes_path(confirmation_token: confirmation_token)

      6.times do
        fill_confirmation_code(code)
        sleep 0.1
      end
    end

    after do
      DecidimApp::RackAttack.disable_rack_attack!
    end

    it "throttles after 5 attempts per minute" do
      expect(page).to have_content("Your connection has been slowed because server received too many requests.")
    end
  end
end
