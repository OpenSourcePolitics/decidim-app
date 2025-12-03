# frozen_string_literal: true

require "spec_helper"

describe "Proposals" do
  include ActionView::Helpers::TextHelper
  include_context "with a component"
  let(:manifest_name) { "proposals" }

  let!(:category) { create(:category, participatory_space: participatory_process) }
  let!(:scope) { create(:scope, organization:) }
  let!(:user) { create(:user, :confirmed, organization:) }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization:, scope:) }

  let(:address) { "Some address" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  let(:proposal_title) { translated(proposal.title) }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  matcher :have_author do |name|
    match { |node| node.has_selector?("[data-author]", text: name) }
    match_when_negated { |node| node.has_no_selector?("[data-author]", text: name) }
  end

  matcher :have_creation_date do |date|
    match { |node| node.has_selector?(".author-data__extra", text: date) }
    match_when_negated { |node| node.has_no_selector?(".author-data__extra", text: date) }
  end

  context "when listing proposals in a participatory process" do
    shared_examples_for "a random proposal ordering" do
      let!(:lucky_proposal) { create(:proposal, component:) }
      let!(:unlucky_proposal) { create(:proposal, component:) }
      let!(:lucky_proposal_title) { translated(lucky_proposal.title) }
      let!(:unlucky_proposal_title) { translated(unlucky_proposal.title) }

      it "lists the proposals ordered randomly by default" do
        visit_component

        expect(page).to have_css("a", text: "Random")
        expect(page).to have_css("[id^='proposals__proposal']", count: 2)
        expect(page).to have_css("[id^='proposals__proposal']", text: lucky_proposal_title)
        expect(page).to have_css("[id^='proposals__proposal']", text: unlucky_proposal_title)
        expect(page).to have_author(lucky_proposal.creator_author.name)
      end
    end

    context "when maps are enabled" do
      let(:component) { create(:proposal_component, :with_geocoding_enabled, participatory_space: participatory_process) }

      let!(:author_proposals) { create_list(:proposal, 2, :participant_author, :published, component:) }
      let!(:group_proposals) { create_list(:proposal, 2, :user_group_author, :published, component:) }
      let!(:official_proposals) { create_list(:proposal, 2, :official, :published, component:) }

      # We are providing a list of coordinates to make sure the points are scattered all over the map
      # otherwise, there is a chance that markers can be clustered, which may result in a flaky spec.
      before do
        coordinates = [
          [-95.501705376541395, 95.10059236654689],
          [-95.501705376541395, -95.10059236654689],
          [95.10059236654689, -95.501705376541395],
          [95.10059236654689, 95.10059236654689],
          [142.15275006889419, -33.33377235135252],
          [33.33377235135252, -142.15275006889419],
          [-33.33377235135252, 142.15275006889419],
          [-142.15275006889419, 33.33377235135252],
          [-55.28745034772282, -35.587843900166945]
        ]
        Decidim::Proposals::Proposal.where(component:).geocoded.each_with_index do |proposal, index|
          proposal.update!(latitude: coordinates[index][0], longitude: coordinates[index][1]) if coordinates[index]
        end

        visit_component
      end

      it "shows markers for selected proposals" do
        expect(page).to have_css(".leaflet-marker-icon", count: 5)
        within "#panel-dropdown-menu-origin" do
          click_filter_item "Official"
        end
        # make the page reload
        visit "#{current_path}?#{URI.parse(current_url).query}"
        expect(page).to have_css(".leaflet-marker-icon", count: 2, wait: 10)
      end
    end

    it_behaves_like "accessible page" do
      before { visit_component }
    end

    it "lists all the proposals" do
      create(:proposal_component,
             manifest:,
             participatory_space: participatory_process)

      create_list(:proposal, 3, component:)

      visit_component
      expect(page).to have_css("[id^='proposals__proposal']", count: 3)
    end

    describe "editable content" do
      it_behaves_like "editable content for admins" do
        let(:target_path) { main_component_path(component) }
      end
    end

    context "when comments have been moderated" do
      let(:proposal) { create(:proposal, component:) }
      let(:author) { create(:user, :confirmed, organization: component.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: proposal) }
      let!(:moderation) { create(:moderation, reportable: comments.first, hidden_at: 1.day.ago) }

      it "displays unhidden comments count" do
        visit_component

        within("#proposals__proposal_#{proposal.id}") do
          within(".card__list-metadata") do
            expect(page).to have_css("div", text: 2)
          end
        end
      end
    end

    describe "default ordering" do
      it_behaves_like "a random proposal ordering"
    end

    context "when voting phase is over" do
      let!(:component) do
        create(:proposal_component,
               :with_votes_blocked,
               manifest:,
               participatory_space: participatory_process)
      end

      let!(:most_voted_proposal) do
        proposal = create(:proposal, component:)
        create_list(:proposal_vote, 3, proposal:)
        proposal
      end
      let!(:most_voted_proposal_title) { translated(most_voted_proposal.title) }

      let!(:less_voted_proposal) { create(:proposal, component:) }
      let!(:less_voted_proposal_title) { translated(less_voted_proposal.title) }

      before { visit_component }

      it "lists the proposals ordered by votes by default" do
        expect(page).to have_css("a", text: "Most voted")
        expect(page).to have_css("[id^='proposals__proposal']:first-child", text: most_voted_proposal_title)
        expect(page).to have_css("[id^='proposals__proposal']:last-child", text: less_voted_proposal_title)
      end
    end

    context "when voting is disabled" do
      let!(:component) do
        create(:proposal_component,
               :with_votes_disabled,
               :with_proposal_limit,
               manifest:,
               participatory_space: participatory_process)
      end

      describe "order" do
        it_behaves_like "a random proposal ordering"
      end

      it "shows only links to full proposals" do
        create_list(:proposal, 2, component:)

        visit_component

        expect(page).to have_css("[id^='proposals__proposal']", count: 2)
      end
    end

    context "when there are a lot of proposals" do
      before do
        create_list(:proposal, Decidim::Paginable::OPTIONS.first + 5, component:)
      end

      it "paginates them" do
        visit_component

        expect(page).to have_css("[id^='proposals__proposal']", count: Decidim::Paginable::OPTIONS.first)
        texts = page.all("[id^='proposals__proposal']").map(&:text)
        click_on "Next"

        expect(page).to have_css("[data-pages] [data-page][aria-current='page']", text: "2")

        expect(page).to have_css("[id^='proposals__proposal']", count: 5)
        click_on "Prev"
        # check elements on page one are still the same
        expect(page.all("[id^='proposals__proposal']").map(&:text)).to eq(texts)
      end
    end

    shared_examples "ordering proposals by selected option" do |selected_option|
      let(:first_proposal_title) { translated(first_proposal.title) }
      let(:last_proposal_title) { translated(last_proposal.title) }
      before do
        visit_component
        within ".order-by" do
          expect(page).to have_css("div.order-by a", text: "Random")
          page.find("a", text: "Random").click
          click_on(selected_option)
        end
      end

      it "lists the proposals ordered by selected option" do
        expect(page).to have_css("[id^='proposals__proposal']:first-child", text: first_proposal_title)
        expect(page).to have_css("[id^='proposals__proposal']:last-child", text: last_proposal_title)
      end
    end

    context "when ordering by 'most_voted'" do
      let!(:component) do
        create(:proposal_component,
               :with_votes_enabled,
               manifest:,
               participatory_space: participatory_process)
      end
      let!(:most_voted_proposal) { create(:proposal, component:) }
      let!(:votes) { create_list(:proposal_vote, 3, proposal: most_voted_proposal) }
      let!(:less_voted_proposal) { create(:proposal, component:) }

      it_behaves_like "ordering proposals by selected option", "Most voted" do
        let(:first_proposal) { most_voted_proposal }
        let(:last_proposal) { less_voted_proposal }
      end
    end

    context "when ordering by 'recent'" do
      let!(:older_proposal) { create(:proposal, component:, created_at: 1.month.ago) }
      let!(:recent_proposal) { create(:proposal, component:) }

      it_behaves_like "ordering proposals by selected option", "Recent" do
        let(:first_proposal) { recent_proposal }
        let(:last_proposal) { older_proposal }
      end
    end

    context "when ordering by 'most_followed'" do
      let!(:most_followed_proposal) { create(:proposal, component:) }
      let!(:follows) { create_list(:follow, 3, followable: most_followed_proposal) }
      let!(:less_followed_proposal) { create(:proposal, component:) }

      it_behaves_like "ordering proposals by selected option", "Most followed" do
        let(:first_proposal) { most_followed_proposal }
        let(:last_proposal) { less_followed_proposal }
      end
    end

    context "when ordering by 'most_commented'" do
      let!(:most_commented_proposal) { create(:proposal, component:, created_at: 1.month.ago) }
      let!(:comments) { create_list(:comment, 3, commentable: most_commented_proposal) }
      let!(:less_commented_proposal) { create(:proposal, component:) }

      it_behaves_like "ordering proposals by selected option", "Most commented" do
        let(:first_proposal) { most_commented_proposal }
        let(:last_proposal) { less_commented_proposal }
      end
    end

    context "when ordering by 'most_endorsed'" do
      let!(:most_endorsed_proposal) { create(:proposal, component:, created_at: 1.month.ago) }
      let!(:endorsements) do
        3.times.collect do
          create(:endorsement, resource: most_endorsed_proposal, author: build(:user, organization:))
        end
      end
      let!(:less_endorsed_proposal) { create(:proposal, component:) }

      it_behaves_like "ordering proposals by selected option", "Most endorsed" do
        let(:first_proposal) { most_endorsed_proposal }
        let(:last_proposal) { less_endorsed_proposal }
      end
    end

    context "when ordering by 'with_more_authors'" do
      let!(:most_authored_proposal) { create(:proposal, component:, created_at: 1.month.ago) }
      let!(:coauthorships) { create_list(:coauthorship, 3, coauthorable: most_authored_proposal) }
      let!(:less_authored_proposal) { create(:proposal, component:) }

      it_behaves_like "ordering proposals by selected option", "With more authors" do
        let(:first_proposal) { most_authored_proposal }
        let(:last_proposal) { less_authored_proposal }
      end
    end

    context "when searching proposals" do
      let!(:proposals) do
        [
          create(:proposal, title: "Lorem ipsum dolor sit amet", component:),
          create(:proposal, title: "Donec vitae convallis augue", component:),
          create(:proposal, title: "Pellentesque habitant morbi", component:)
        ]
      end

      before do
        visit_component
      end

      it "finds the correct proposal" do
        within "form.new_filter" do
          find("input[name='filter[search_text_cont]']", match: :first).set("lorem")
          find("*[type=submit]").click
        end

        expect(page).to have_content("Lorem ipsum dolor sit amet")
      end
    end

    context "when paginating" do
      let!(:collection) { create_list(:proposal, collection_size, component:) }
      let!(:resource_selector) { "[id^='proposals__proposal']" }

      it_behaves_like "a paginated resource"
    end

    context "when component is not commentable" do
      let!(:resources) { create_list(:proposal, 3, component:) }

      it_behaves_like "an uncommentable component"
    end
  end

  describe "viewing mode for proposals" do
    let!(:proposal) { create(:proposal, :evaluating, component:) }

    context "when participants interact with the proposal view" do
      it "provides an option for toggling between list and grid views" do
        visit_component
        expect(page).to have_css("use[href*='layout-grid-fill']")
        expect(page).to have_css("use[href*='list-check']")
      end
    end

    context "when participants are viewing a grid of proposals" do
      it "shows a grid of proposals with images" do
        visit_component

        # Check that grid view is not the default
        expect(page).to have_no_css(".card__grid-grid")

        # Switch to grid view
        find("a[href*='view_mode=grid']").click
        expect(page).to have_css(".card__grid-grid")
        expect(page).to have_css(".card__grid-img img, .card__grid-img svg")

        # Revisit the component and check session storage
        visit_component
        expect(page).to have_css(".card__grid-grid")
      end
    end

    context "when participants are filtering proposals" do
      let!(:evaluating_proposals) { create_list(:proposal, 3, :evaluating, component:) }
      let!(:accepted_proposals) { create_list(:proposal, 5, :accepted, component:) }

      it "filters the proposals and keeps the filter when changing the view mode" do
        visit_component
        uncheck "Evaluating"

        expect(page).to have_css("[id^='proposals__proposal']", count: 5)

        find("a[href*='view_mode=grid']").click

        expect(page).to have_css(".card__grid-img svg#ri-proposal-placeholder-card-g", count: 5)
        expect(page).to have_css("[id^='proposals__proposal']", count: 5)
      end
    end

    context "when participants are viewing a list of proposals" do
      it "shows a list of proposals" do
        visit_component
        find("a[href*='view_mode=list']").click
        expect(page).to have_css(".card__list-list")
      end
    end

    context "when proposals does not have attachments" do
      it "shows a placeholder image" do
        visit_component
        find("a[href*='view_mode=grid']").click
        expect(page).to have_css(".card__grid-img svg#ri-proposal-placeholder-card-g")
      end
    end

    context "when proposals have attachments" do
      let!(:proposal) { create(:proposal, component:) }
      let!(:attachment) { create(:attachment, attached_to: proposal) }

      before do
        component.update!(settings: { attachments_allowed: true })
      end

      it "shows the proposal image" do
        visit_component

        expect(page).to have_no_css(".card__grid-img img[src*='proposal_image_placeholder.svg']")
        expect(page).to have_css(".card__grid-img img")
      end
    end
  end
end
