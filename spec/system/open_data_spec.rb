# frozen_string_literal: true

require "spec_helper"

describe "Open data page" do
  let(:organization) { create(:organization, available_locales: %w(en fr), default_locale: :fr) }

  before do
    switch_to_host(organization.host)
  end

  context "when visiting the page in French" do
    before do
      visit decidim.open_data_path(locale: :fr)
    end

    it "renders the French help for proposal comments and initiatives" do
      expect(page).to have_css("h4", text: "proposal_comments")
      expect(page).to have_css("h4", text: "initiatives")
      expect(page).to have_content("Le secteur de cette initiative")
      expect(page).to have_no_content("The comment itself")
    end
  end

  context "when a help translation is missing in the current locale" do
    before do
      allow(I18n).to receive(:translate).and_wrap_original do |original, key = nil, **options|
        missing = key.to_s == "proposal_comments" && options[:scope] == "decidim.open_data.help" && options[:locale].nil?
        original.call(missing ? "missing_in_this_locale" : key, **options)
      end

      visit decidim.open_data_path(locale: :fr)
    end

    it "renders the page with the English help instead" do
      expect(page).to have_css("h4", text: "proposal_comments")
      expect(page).to have_content("The comment itself")
    end
  end
end
