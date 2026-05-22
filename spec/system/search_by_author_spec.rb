# frozen_string_literal: true

require "spec_helper"

describe "Search by author name" do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:proposals_component) { create(:component, manifest_name: :proposals, participatory_space: participatory_process) }
  let(:meetings_component) { create(:component, manifest_name: :meetings, participatory_space: participatory_process) }
  let(:debates_component) { create(:component, manifest_name: :debates, participatory_space: participatory_process) }

  let(:another_participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:another_proposals_component) { create(:component, manifest_name: :proposals, participatory_space: another_participatory_process) }
  let(:another_meetings_component) { create(:component, manifest_name: :meetings, participatory_space: another_participatory_process) }

  let(:alice) { create(:user, :confirmed, name: "Alice Dupont", organization:) }
  let(:bob) { create(:user, :confirmed, name: "Bob Martin", organization:) }
  let(:other_org_user) { create(:user, :confirmed, name: "Alice Clone", organization: create(:organization)) }

  let!(:alice_proposal) do
    create(:proposal, :published, component: proposals_component, users: [alice]).tap(&:try_update_index_for_search_resource)
  end

  let!(:alice_proposal_another_process) do
    create(:proposal, :published, component: another_proposals_component, users: [alice]).tap(&:try_update_index_for_search_resource)
  end

  let!(:alice_meeting) do
    create(:meeting, :published, component: meetings_component, author: alice).tap(&:try_update_index_for_search_resource)
  end

  let!(:alice_meeting_another_process) do
    create(:meeting, :published, component: another_meetings_component, author: alice).tap(&:try_update_index_for_search_resource)
  end

  let!(:alice_debate) do
    create(:debate, component: debates_component, author: alice).tap(&:try_update_index_for_search_resource)
  end

  let!(:bob_proposal) do
    create(:proposal, :published, component: proposals_component, users: [bob]).tap(&:try_update_index_for_search_resource)
  end

  let!(:bob_meeting) do
    create(:meeting, :published, component: meetings_component, author: bob).tap(&:try_update_index_for_search_resource)
  end

  let!(:coauthored_proposal) do
    create(:proposal, :published, component: proposals_component, users: [alice, bob]).tap(&:try_update_index_for_search_resource)
  end

  before do
    switch_to_host(organization.host)
  end

  describe "when searching for Alice" do
    before { visit decidim.search_path(term: alice.name) }

    it "finds Alice's profile" do
      expect(page).to have_content(alice.name)
      expect(page).to have_content("@#{alice.nickname}")
    end

    it "finds her proposal in the first process" do
      expect(page).to have_content(translated(alice_proposal.title))
    end

    it "finds her proposal in another process" do
      expect(page).to have_content(translated(alice_proposal_another_process.title))
    end

    it "finds her meeting in the first process" do
      expect(page).to have_content(translated(alice_meeting.title))
    end

    it "finds her meeting in another process" do
      expect(page).to have_content(translated(alice_meeting_another_process.title))
    end

    it "finds her debate" do
      expect(page).to have_content(translated(alice_debate.title))
    end

    it "finds the proposal she coauthored with Bob" do
      expect(page).to have_content(translated(coauthored_proposal.title))
    end

    it "does not find Bob's proposal" do
      expect(page).to have_no_content(translated(bob_proposal.title))
    end

    it "does not find Bob's meeting" do
      expect(page).to have_no_content(translated(bob_meeting.title))
    end
  end

  describe "when searching for Bob" do
    before { visit decidim.search_path(term: bob.name) }

    it "finds Bob's profile" do
      expect(page).to have_content(bob.name)
      expect(page).to have_content("@#{bob.nickname}")
    end

    it "finds his proposal" do
      expect(page).to have_content(translated(bob_proposal.title))
    end

    it "finds his meeting" do
      expect(page).to have_content(translated(bob_meeting.title))
    end

    it "finds the proposal he coauthored with Alice" do
      expect(page).to have_content(translated(coauthored_proposal.title))
    end

    it "does not find Alice's proposal" do
      expect(page).to have_no_content(translated(alice_proposal.title))
    end

    it "does not find Alice's debate" do
      expect(page).to have_no_content(translated(alice_debate.title))
    end
  end

  describe "when a proposal belongs to an unpublished component" do
    let(:unpublished_component) { create(:component, :unpublished, manifest_name: :proposals, participatory_space: participatory_process) }
    let!(:proposal_in_unpublished_component) do
      create(:proposal, :published, component: unpublished_component, users: [alice]).tap(&:try_update_index_for_search_resource)
    end

    before { visit decidim.search_path(term: alice.name) }

    it "does not find the proposal" do
      expect(page).to have_no_content(translated(proposal_in_unpublished_component.title))
    end
  end

  describe "when a user belongs to another organization" do
    let!(:other_org_proposal) do
      other_process = create(:participatory_process, :with_steps, organization: other_org_user.organization)
      other_component = create(:component, manifest_name: :proposals, participatory_space: other_process)
      create(:proposal, :published, component: other_component, users: [other_org_user]).tap(&:try_update_index_for_search_resource)
    end

    before { visit decidim.search_path(term: "Alice") }

    it "does not find the other organization user" do
      expect(page).to have_no_content(other_org_user.name)
    end

    it "does not find the other organization proposal" do
      expect(page).to have_no_content(translated(other_org_proposal.title))
    end
  end

  describe "when a user is deleted" do
    before do
      alice.delete
      visit decidim.search_path(term: "Alice")
    end

    it "does not find the deleted user" do
      expect(page).to have_no_content("@#{alice.nickname}")
    end
  end

  describe "when searching for a user with no contributions" do
    let(:user_no_contributions) { create(:user, :confirmed, name: "Jean Sans Contributions", organization:) }

    before do
      user_no_contributions.try_update_index_for_search_resource
      visit decidim.search_path(term: user_no_contributions.name)
    end

    it "finds the user profile" do
      expect(page).to have_content(user_no_contributions.name)
      expect(page).to have_content("@#{user_no_contributions.nickname}")
    end

    it "does not find any proposal" do
      expect(page).to have_css("[data-resource-type='Decidim::Proposals::Proposal']", count: 0)
    rescue StandardError
      expect(page).to have_content("Proposals\n0")
    end
  end

  describe "when searching by nickname" do
    before { visit decidim.search_path(term: alice.nickname) }

    it "finds Alice's profile" do
      expect(page).to have_content(alice.name)
      expect(page).to have_content("@#{alice.nickname}")
    end
  end

  describe "when a user is blocked" do
    before do
      alice.update!(blocked: true, blocked_at: Time.current)
      alice.try_update_index_for_search_resource
      visit decidim.search_path(term: alice.name)
    end

    it "does not find the blocked user" do
      expect(page).to have_no_content("@#{alice.nickname}")
    end
  end
end
