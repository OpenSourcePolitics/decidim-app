# frozen_string_literal: true

shared_examples_for "has embedded video in description" do |description_attribute_name, count: 1|
  let(description_attribute_name) do
    {
      en: <<~HTML
        <p>Description</p>
        <div class="editor-content-videoEmbed" data-video-embed="#{iframe_src}">
          <div>
            <iframe src="#{iframe_src}" title="Test video" frameborder="0"></iframe>
          </div>
        </div>
      HTML
    }
  end
  let(:iframe_src) { "http://www.example.org" }
  let!(:cookie_warning) { "You need to enable all cookies in order to see this content" }

  context "when cookies are rejected" do
    before do
      page.driver.browser.manage.add_cookie(
        name: "decidim-consent",
        value: { essential: true, marketing: false, analytics: false, preferences: false }.to_json
      )
      page.refresh
    end

    it "disables iframe" do
      expect(page).to have_content(cookie_warning)
      expect(page).to have_no_css("iframe")
    end
  end

  context "when cookies are accepted" do
    before do
      page.driver.browser.manage.add_cookie(
        name: "decidim-consent",
        value: { essential: true, marketing: true, analytics: true, preferences: true }.to_json
      )
      page.refresh
    end

    it "shows iframe" do
      expect(page).to have_no_content(cookie_warning)
      expect(page).to have_css("iframe", count:)
    end
  end
end
