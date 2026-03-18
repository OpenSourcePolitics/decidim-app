# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
describe "Admin adds iframe on proposals component" do
  # rubocop:enable RSpec/DescribeClass
  let!(:manifest_name) { "proposals" }
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let!(:component) { create(:proposal_component, participatory_space: participatory_process) }
  let(:admin) { create(:user, :admin, :confirmed, organization:) }

  context "when adding an iframe" do
    before do
      switch_to_host(organization.host)
      login_as admin, scope: :user
      visit decidim_admin_participatory_processes.components_path(participatory_process)
      within ".component-#{component.id}" do
        find("a[title='Configure']").click
      end
      check I18n.t("decidim.components.proposals.settings.global.enable_iframe")
    end

    it "shows the url input" do
      # when checking enable_iframe, the iframe_url div is displayed
      expect(page).to have_css("div.iframe_url_container")
    end

    context "and adding valid urls" do
      it "adds valid url and can update component" do
        # provide valid url
        fill_in "component[settings][iframe_url]", with: "https://api.example.org"
        #  no error message displayed
        expect(page).to have_no_css("p.url_input_error")
        # can update component
        click_link_or_button "Update"
        expect(page).to have_content("The component was updated successfully.")
      end
    end

    context "and adding invalid url" do
      it "gets an error message and can't update component" do
        # provide invalid url
        fill_in "component[settings][iframe_url]", with: "api.example.com"
        sleep(1)
        # get an error message
        expect(page).to have_css("p.url_input_error")
        # submit button is disabled
        expect(page).to have_css("button[name='commit'][disabled='true']")
        # providing a good url removes the error
        fill_in "component[settings][iframe_url]", with: "http://api.example.com"
        sleep(1)
        expect(page).to have_no_css("p.url_input_error")
      end

      context "and unchecking enable iframe" do
        it 'can submit the component' do
          # provide invalid url
          fill_in "component[settings][iframe_url]", with: "api.example.com"
          sleep(1)
          # get an error message
          expect(page).to have_css("p.url_input_error")
          # submit button is disabled
          expect(page).to have_css("button[name='commit'][disabled='true']")
          # unchecking the enable_iframe removes the error and enables submit button again
          uncheck I18n.t("decidim.components.proposals.settings.global.enable_iframe")
          sleep(1)
          # error message removed
          expect(page).to have_no_css("p.url_input_error")
          # can update component
          click_link_or_button "Update"
          expect(page).to have_content("The component was updated successfully.")
        end
      end
    end
  end
end
