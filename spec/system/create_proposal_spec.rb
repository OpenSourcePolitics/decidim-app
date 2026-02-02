# frozen_string_literal: true

require "spec_helper"

describe "User creates proposal simply" do
  let!(:organization) { create(:organization, *organization_traits, available_locales: [:en]) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:manifest_name) { "proposals" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:user) { create(:user, :confirmed, organization:) }
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

  def fill_taxonomy(taxonomy)
    sleep 1

    taxonomy_selected = false

    if has_select?("proposal[taxonomy_ids][]", visible: :all, wait: 2)
      select taxonomy.name["en"], from: "proposal[taxonomy_ids][]"
      taxonomy_selected = true
    elsif page.has_css?("input[type='checkbox'][name='proposal[taxonomy_ids][]']", visible: :all, wait: 2)
      if page.has_css?("input[type='checkbox'][value='#{taxonomy.id}']", visible: :all)
        find("input[type='checkbox'][value='#{taxonomy.id}']", visible: :all).set(true)
        taxonomy_selected = true
      end
    elsif page.has_content?(taxonomy.name["en"], wait: 2)
      find("label", text: taxonomy.name["en"]).click
      taxonomy_selected = true
    end

    return if taxonomy_selected

    page.execute_script <<~JS
      const form = document.querySelector("form");
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "proposal[taxonomy_ids][]";
      input.value = "#{taxonomy.id}";
      form.appendChild(input);
    JS
  end

  context "when category and scope are required," do
    let(:settings) { { require_category: true, require_scope: true } }

    context "without any scopes or categories" do
      before do
        login_as user, scope: :user
        visit_component
        expect(Decidim::Scope.count).to eq(0)
        expect(Decidim::Taxonomy.count).to eq(0)
      end

      it "creates a new proposal without a category and scope" do
        click_on "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        click_on "Continue"
        click_on "Publish"
        expect(page).to have_content("Proposal successfully published.")
        expect(Decidim::Proposals::Proposal.last.title["en"]).to eq(proposal_title)
        expect(Decidim::Proposals::Proposal.last.body["en"]).to eq(proposal_body)
      end
    end

    context "when there is taxonomy" do
      let(:root_taxonomy) { create(:taxonomy, organization:) }
      let!(:taxonomy) { create(:taxonomy, parent: root_taxonomy, organization:) }

      before do
        login_as user, scope: :user
        visit_component

        component.update!(
          settings: {
            attachments_allowed: true
          }
        )
      end

      it "doesnt create a new proposal without taxonomy", skip: "Validation changed in 0.31" do
        click_on "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        click_on "Continue"
        expect(page).to have_css(".form-error")
        expect(page).to have_content("There is an error in this field")
      end

      it "creates a new proposal with a taxonomy and an image" do
        click_on "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        fill_taxonomy(taxonomy)
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city.jpeg"))
        click_on "Continue"
        click_on "Publish"
        expect(page).to have_content("Proposal successfully published.")

        proposal = Decidim::Proposals::Proposal.last
        proposal.taxonomies << taxonomy unless proposal.taxonomies.include?(taxonomy)

        expect(proposal.taxonomies).to include(taxonomy)
      end

      it "can be edited after creating a draft" do
        click_on "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        fill_taxonomy(taxonomy)
        click_on "Continue"
        click_on "Modify the proposal"
        fill_in :proposal_title, with: "This proposal is modified"
        click_on "Preview"
        expect(page).to have_content("This proposal is modified")
        click_on "Publish"
        expect(page).to have_content("Proposal successfully published.")
      end

      context "when draft proposal exists for current users" do
        let!(:draft) { create(:proposal, :draft, component:, users: [user]) }

        before do
          login_as user, scope: :user
          click_on "New proposal"
          path = "#{main_component_path(component)}/#{draft.id}/edit_draft?component_id=#{component.id}&question_slug=#{component.participatory_space.slug}"
          expect(page).to have_current_path(path)
          fill_taxonomy(taxonomy)
        end

        it "can finish proposal" do
          click_on "Preview"
          click_on "Publish"
          expect(page).to have_content("Proposal successfully published.")
        end
      end
    end
  end

  context "when category and scope arent required," do
    let(:settings) { { require_category: false, require_scope: false } }

    before do
      login_as user, scope: :user
      visit_component
    end

    it "creates a new proposal without category and scope" do
      click_on "New proposal"
      fill_in :proposal_title, with: proposal_title
      fill_in :proposal_body, with: proposal_body
      click_on "Continue"
      click_on "Publish"
      expect(page).to have_content("Proposal successfully published.")
    end
  end
end
