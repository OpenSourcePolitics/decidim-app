# frozen_string_literal: true

require "spec_helper"

describe "User creates proposal simply" do
  let!(:organization) { create :organization, *organization_traits, available_locales: [:en] }
  let!(:participatory_process) { create :participatory_process, :with_steps, organization: }
  let(:manifest_name) { "proposals" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:user) { create :user, :confirmed, organization: }
  let(:settings) { nil }
  let!(:component) do
    create(:proposal_component,
           :with_creation_enabled,
           :with_attachments_allowed,
           manifest:,
           participatory_space: participatory_process,
           settings:)
  end
  let(:organization_traits) { [] }

  let(:proposal_title) { Faker::Lorem.paragraph }
  let(:proposal_body) { Faker::Lorem.paragraph }

  def visit_component
    if organization_traits.include?(:secure_context)
      switch_to_secure_context_host
    else
      switch_to_host(organization.host)
    end
    page.visit main_component_path(component)
  end

  before do
    login_as user, scope: :user
    visit_component
  end

  context "when category and scope are required," do
    let(:settings) { { require_category: true, require_scope: true } }

    context "without any scopes or categories" do
      before do
        expect(Decidim::Scope.count).to eq(0)
        expect(Decidim::Category.count).to eq(0)
      end

      it "creates a new proposal without a category and scope" do
        click_link_or_button "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        click_link_or_button "Continue"
        click_link_or_button "Publish"
        expect(page).to have_content("Proposal successfully published.")
        expect(Decidim::Proposals::Proposal.last.title["en"]).to eq(proposal_title)
        expect(Decidim::Proposals::Proposal.last.body["en"]).to eq(proposal_body)
      end
    end

    context "when scopes are enabled and there is subscope and category" do
      before do
        component.update(settings: { scopes_enabled: true, scope_id: parent_scope.id, attachments_allowed: true })
      end

      let(:parent_scope) { create(:scope, organization:) }
      let!(:scope) { create(:subscope, parent: parent_scope) }
      let!(:category) { create(:category, participatory_space: participatory_process) }

      it "doesnt create a new proposal without category and scope" do
        click_link_or_button "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        click_link_or_button "Continue"
        expect(page).to have_css(".form-error")
        expect(page).to have_content("There is an error in this field")
      end

      it "creates a new proposal with a category and scope" do
        click_link_or_button "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        fill_category_and_scope(category, scope)
        click_link_or_button "Continue"
        click_link_or_button "Publish"
        expect(page).to have_content("Proposal successfully published.")
        expect(Decidim::Proposals::Proposal.last.category).to eq(category)
        expect(Decidim::Proposals::Proposal.last.scope).to eq(scope)
      end

      it "can be edited after creating a draft" do
        click_link_or_button "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        fill_category_and_scope(category, scope)
        click_link_or_button "Continue"
        click_link_or_button "Modify the proposal"
        fill_in :proposal_title, with: "This proposal is modified"
        click_link_or_button "Preview"
        expect(page).to have_content("This proposal is modified")
        click_link_or_button "Publish"
        expect(page).to have_content("Proposal successfully published.")
      end

      context "when uploading a file", processing_uploads_for: Decidim::AttachmentUploader do
        it "can add image" do
          click_link_or_button "New proposal"
          fill_in :proposal_title, with: proposal_title
          fill_in :proposal_body, with: proposal_body
          fill_category_and_scope(category, scope)
          dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city.jpeg"))
          click_link_or_button "Continue"
          click_link_or_button "Publish"
          expect(page).to have_content("Proposal successfully published.")
        end
      end

      context "when draft proposal exists for current users" do
        let!(:draft) { create(:proposal, :draft, component:, users: [user]) }

        before do
          click_link_or_button "New proposal"
          path = "#{main_component_path(component)}/#{draft.id}/edit_draft?component_id=#{component.id}&question_slug=#{component.participatory_space.slug}"
          expect(page).to have_current_path(path)
          fill_category_and_scope(category, scope)
        end

        it "can finish proposal" do
          click_link_or_button "Preview"
          click_link_or_button "Publish"
          expect(page).to have_content("Proposal successfully published.")
        end
      end
    end
  end

  context "when category and scope arent required," do
    let(:settings) { { require_category: false, require_scope: false } }

    it "creates a new proposal without category and scope" do
      click_link_or_button "New proposal"
      fill_in :proposal_title, with: proposal_title
      fill_in :proposal_body, with: proposal_body
      click_link_or_button "Continue"
      click_link_or_button "Publish"
      expect(page).to have_content("Proposal successfully published.")
    end
  end

  def fill_category_and_scope(category, scope)
    select category.name["en"], from: :proposal_category_id
    select scope.name["en"], from: :proposal_scope_id
  end
end
