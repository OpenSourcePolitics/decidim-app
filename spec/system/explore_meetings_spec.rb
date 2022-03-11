# frozen_string_literal: true

require "spec_helper"

describe "Explore meeting directory", :slow, type: :system do
  let(:directory) do
    Decidim::Meetings::DirectoryEngine.routes.url_helpers.root_path
  end
  let(:organization) { create(:organization) }
  let(:components) do
    create_list(:meeting_component, 3, organization: organization)
  end
  let!(:meetings) do
    components.flat_map do |component|
      create_list(:meeting, 2, :published, component: component)
    end
  end

  before do
    switch_to_host(organization.host)
    visit directory
  end

  it "shows all the upcoming meetings" do
    within "#meetings" do
      expect(page).to have_css(".card--meeting", count: 6)
    end

    expect(page).to have_css("#meetings-count", text: "6 MEETINGS")
  end

  context "when there's a past meeting" do
    let!(:past_meeting) do
      create(:meeting, :published, component: components.last, start_time: 1.week.ago)
    end

    it "allows filtering by past events" do
      within ".filters" do
        choose "Past"
      end

      expect(page).to have_content(past_meeting.title["en"])
      expect(page).to have_css("#meetings-count", text: "1 MEETING")
    end
  end

  context "when no upcoming meetings scheduled" do
    let!(:meetings) do
      create_list(:meeting, 2, component: component, start_time: 4.days.ago, end_time: 2.days.ago)
    end

    before do
      visit directory
    end

    it "only shows the past meetings" do
      visit_component
      expect(page).to have_css(".card--meeting", count: 2)
    end

    it "allows filtering by space" do
      expect(page).to have_content(assembly_meeting.title["en"])

      # Since in the first load all the meeting are present, we need can't rely on
      # have_content to wait for the card list to change. This is a hack to
      # reset the contents to no meetings at all, and then showing only the upcoming
      # assembly meetings.
      within ".filters" do
        choose "Past"
      end

      expect(page).to have_no_css(".card--meeting")

      within ".filters" do
        choose "Assemblies"
        choose "Upcoming"
      end

      expect(page).to have_content(assembly_meeting.title["en"])
      expect(page).to have_css(".card--meeting", count: 1)
      expect(page).to have_css("#meetings-count", text: "1 MEETING")
    end
  end
end
