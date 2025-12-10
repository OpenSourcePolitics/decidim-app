# frozen_string_literal: true

require "spec_helper"

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Forcer les jobs en mode inline pour les tests system
    ActiveJob::Base.queue_adapter = :inline
  end

  config.after(:each, type: :system) do
    # Réinitialiser si nécessaire
    ActiveJob::Base.queue_adapter = :test
  end
end

describe "search process and descendants" do
  include ActionView::Helpers::SanitizeHelper

  let(:organization) { create(:organization) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:participatory_process) { create(:participatory_process, :published, organization:) }
  let(:component) { create(:meeting_component, participatory_space: participatory_process) }
  let!(:meetings) { create_list(:meeting, 3, :published, component:) }
  let!(:comment) { create(:comment, commentable: meetings.first) }
  let!(:term) { strip_tags(translated(meetings.first.title)) }
  let!(:term_two) { strip_tags(translated(comment.body)) }

  context "when admin unpublishes a process with descendants" do
    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
      click_on "Unpublish"
      perform_enqueued_jobs if respond_to?(:perform_enqueued_jobs)
      participatory_process.reload
      expect(participatory_process.published_at).to be_nil
      component.reload
      meetings.each(&:reload)
      comment.reload
    end

    it "descendants are not found by search" do
      visit decidim.root_path
      expect(page).to have_css("#form-search_topbar")

      # find meeting
      within "#form-search_topbar" do
        fill_in "term", with: term
        find("input#input-search").native.send_keys :enter
      end

      expect(page).to have_current_path decidim.search_path, ignore_query: true
      expect(page).to have_content("0 Results for the search")
      expect(page).to have_css(".filter-search.filter-container")

      # find comment
      within "#form-search_topbar" do
        fill_in "term", with: term_two
        find("input#input-search").native.send_keys :enter
      end

      expect(page).to have_current_path decidim.search_path, ignore_query: true
      expect(page).to have_content("0 Results for the search")
      expect(page).to have_css(".filter-search.filter-container")
    end
  end

  context "when admin publishes a process with descendants" do
    let!(:participatory_process) { create(:participatory_process, :unpublished, organization:) }

    before do
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
      click_on "Publish"
      perform_enqueued_jobs if respond_to?(:perform_enqueued_jobs)
      participatory_process.reload
      expect(participatory_process.published_at).not_to be_nil
      component.reload
      meetings.each(&:reload)
      comment.reload
    end

    it "descendants are found by search" do
      visit decidim.root_path
      expect(page).to have_css("#form-search_topbar")

      # find meeting
      within "#form-search_topbar" do
        fill_in "term", with: term
        find("input#input-search").native.send_keys :enter
      end

      expect(page).to have_current_path decidim.search_path, ignore_query: true
      expect(page).to have_content(/results for the search: "#{term}"/i)
      expect(page).to have_css(".filter-search.filter-container")

      # find comment
      within "#form-search_topbar" do
        fill_in "term", with: term_two
        find("input#input-search").native.send_keys :enter
      end

      expect(page).to have_current_path decidim.search_path, ignore_query: true
      expect(page).to have_content(/results for the search: "#{term_two}"/i)
      expect(page).to have_css(".filter-search.filter-container")
    end
  end
end
