# frozen_string_literal: true

require "spec_helper"

describe "Export" do
  include_context "when admins initiative"

  let!(:votes) { create_list(:initiative_user_vote, 5, initiative: initiative) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  it "downloads the PDF file", :download do
    visit decidim_admin_initiatives.initiatives_path

    within find("tr", text: translated(initiative.title)) do
      page.find(".action-icon--edit").click
    end

    click_link "Export PDF of signatures"
    within ".confirm-reveal" do
      click_link "OK"
    end

    expect(File.basename(download_path)).to include("votes_#{initiative.id}.pdf")
  end
end
