# frozen_string_literal: true

require "spec_helper"

describe "Open data page" do
  let(:organization) { create(:organization, available_locales: %w(en fr), default_locale: :fr) }

  before do
    switch_to_host(organization.host)
  end

  context "when a help translation is missing in the current locale" do
    before do
      skip "fr now translates decidim.open_data.help.proposal_comments" if I18n.exists?("decidim.open_data.help.proposal_comments", :fr)

      visit decidim.open_data_path(locale: :fr)
    end

    it "renders the page with the English help instead" do
      expect(page).to have_css("h4", text: "proposal_comments")
      expect(page).to have_content("The comment itself")
    end
  end
end
