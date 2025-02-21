# frozen_string_literal: true

require "spec_helper"

describe "Admin double authentication", type: :system do
  include Decidim::SanitizeHelper

  let(:organization) { create :organization, default_locale: :en, available_locales: [:en, :es, :ca, :fr] }
  let(:admin) { create :user, :admin, :confirmed, organization: organization }
  let!(:setting) { Decidim::AdminMultiFactor::Setting.create!(enable_multifactor: true, email: true, sms: true, organization: organization) }

  before do
    switch_to_host(organization.host)
  end

  describe "Access back office" do
    before do
      login_as admin, scope: :user
      allow_any_instance_of(Decidim::AdminMultiFactor::BaseVerification).to receive(:generate_code).and_return("1234")
    end

    it "can access back office with email" do
      visit decidim.root_path
      click_link admin.name.to_s
      li = page.all("ul.is-dropdown-submenu li")
      li[4].click
      expect(page).to have_content("Elevate access rights")
      links = page.all("a.button.button--social")
      links[0].click # first link is Email
      expect(page).to have_content("Please enter the code:")
      fill_in "digit1", with: 1
      fill_in "digit2", with: 2
      fill_in "digit3", with: 3
      fill_in "digit4", with: 4
      click_link_or_button "Submit"
      expect(page).to have_content("Welcome to the Admin Panel.")
    end

    it "can access back office with sms" do
      visit decidim.root_path
      click_link admin.name.to_s
      li = page.all("ul.is-dropdown-submenu li")
      li[4].click
      expect(page).to have_content("Elevate access rights")
      links = page.all("a.button.button--social")
      links[1].click # second link is Sms
      fill_in "sms_code[phone_number]", with: "0612345678"
      click_link_or_button "Submit"
      expect(page).to have_content("Please enter the code:")
      fill_in "digit1", with: 1
      fill_in "digit2", with: 2
      fill_in "digit3", with: 3
      fill_in "digit4", with: 4
      click_link_or_button "Submit"
      expect(page).to have_content("Welcome to the Admin Panel.")
    end
  end
end
