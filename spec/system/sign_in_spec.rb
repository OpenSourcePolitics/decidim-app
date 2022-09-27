# frozen_string_literal: true

require "spec_helper"
require_relative "examples/other_password_examples"

describe "Sign in", type: :system do
  let(:organization) { create(:organization) }

  before do
    switch_to_host(organization.host)
  end

  it_behaves_like "on/off sign in passwords"

  it "uses email abide validation" do
    visit decidim.new_user_session_path

    expect(page).to have_field("session_user_email")
    within ".new_user" do
      fill_in :session_user_email, with: "inv@lid"
      sleep 0.3

      expect(page).to have_css(".form-error")
      expect(page).to have_content("Please enter a valid email address")

      fill_in :session_user_email, with: "valid@example.org"
      sleep 0.3

      expect(page).not_to have_css(".form-error")
      expect(page).not_to have_content("Please enter a valid email address")
    end
  end
end
