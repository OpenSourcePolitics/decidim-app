# frozen_string_literal: true

require "spec_helper"

describe "User edits proposals" do
  include_context "with a component"
  let!(:organization) { create :organization, available_locales: [:en] }
  let!(:participatory_process) { create :participatory_process, :with_steps, organization: }
  let(:manifest_name) { "proposals" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:user) { create :user, :confirmed, organization: }
  let(:settings) { nil }
  let(:component) do
    create(:proposal_component,
           :with_creation_enabled,
           :with_attachments_allowed,
           manifest:,
           participatory_space: participatory_process,
           settings:)
  end
  let(:organization_traits) { [] }

  let(:proposal_title) { "This is my great proposal to change the world" }
  let(:proposal_body) { "This is my great proposal to change the world" }

  def visit_component
    if organization_traits&.include?(:secure_context)
      switch_to_secure_context_host
    else
      switch_to_host(organization.host)
    end
    page.visit main_component_path(component)
  end

  context "when user has proposal" do
    let!(:proposal) { create(:proposal, users: [user], component:) }
    let(:settings) { { require_category: false, require_scope: false, attachments_allowed: true } }

    before do
      login_as user, scope: :user
      visit_component
      click_link_or_button translated(proposal.title)
      click_link_or_button "Edit proposal"
      fill_in :proposal_title, with: proposal_title
      fill_in :proposal_body, with: proposal_body
    end

    it "can be edited" do
      click_link_or_button "Send"
      expect(page).to have_content("Proposal successfully updated")
      expect(Decidim::Proposals::Proposal.last.title["en"]).to eq(proposal_title)
      expect(Decidim::Proposals::Proposal.last.body["en"]).to eq(proposal_body)
    end

    context "when uploading a file", processing_uploads_for: Decidim::AttachmentUploader do
      it "can add image" do
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city.jpeg"))
        click_link_or_button "Send"
        expect(page).to have_content("Proposal successfully updated")
      end

      it "can add images" do
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city.jpeg"))
        click_link_or_button "Send"
        click_link_or_button "Edit proposal"
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city2.jpeg"), remove_before: true)
        click_link_or_button "Send"
        expect(page).to have_content("Proposal successfully updated")
        expect(Decidim::Proposals::Proposal.last.attachments.count).to eq(1)
      end

      it "can add pdf document" do
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("Exampledocument.pdf"))
        click_link_or_button "Send"
        expect(page).to have_content("Proposal successfully updated")
      end
    end

    context "when proposal has attachment" do
      let!(:proposal) { create(:proposal, users: [user], component:, body: proposal_body, title: proposal_title) }
      let!(:attachment) { create(:attachment, title: { "en" => filename }, file:, attached_to: proposal, weight: 0) }

      context "when proposal has pdf attachment" do
        let(:filename) { "Exampledocument.pdf" }
        let(:file) { Decidim::Dev.test_file(filename, "application/pdf") }

        before do
          login_as user, scope: :user
          visit_component
          click_link_or_button translated(proposal.title)
        end

        it "can remove document attachment" do
          click_link_or_button "Edit proposal"

          click_link_or_button "Edit documents"
          within ".upload-modal" do
            click_link_or_button "Remove"
            click_link_or_button "Save"
          end

          click_link_or_button "Send"
          expect(page).to have_content("Proposal successfully updated.")
          expect(page).to have_no_content("Documents ")
          expect(page).to have_no_link(filename)
          expect(Decidim::Proposals::Proposal.find(proposal.id).attachments).to be_empty
        end
      end

      context "when proposal has card image" do
        let(:filename) { "city.jpeg" }
        let(:file) { Decidim::Dev.test_file(filename, "image/jpeg") }

        before do
          login_as user, scope: :user

          settings = component.settings
          settings.comments_enabled = false
          component.update(settings:)

          visit_component
          click_link_or_button translated(proposal.title), match: :first
        end

        it "can remove card image" do
          click_link_or_button "Edit proposal"

          click_link_or_button "Edit documents"
          within ".upload-modal" do
            click_link_or_button "Remove"
            click_link_or_button "Save"
          end

          click_link_or_button "Send"
          expect(page).to have_content("Proposal successfully updated.")
          expect(page).to have_no_content("Images")
          expect(page).to have_no_link(filename)
          expect(Decidim::Proposals::Proposal.find(proposal.id).attachments).to be_empty
        end

        it "can set new card image" do
          click_link_or_button "Edit proposal"
          dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city2.jpeg"), remove_before: true)

          click_link_or_button "Send"
          expect(page).to have_content("Proposal successfully updated.")
          expect(page).to have_content("Images")

          created_proposal = Decidim::Proposals::Proposal.find(proposal.id)
          expect(created_proposal.attachments.count).to eq(1)
          expect(created_proposal.photos.count).to eq(1)
          expect(created_proposal.photos.first.title["en"]).to eq("city2.jpeg")
        end
      end
    end

    context "when proposal has card image and document image" do
      let!(:proposal) { create(:proposal, users: [user], component:) }

      let!(:card_image) { create(:attachment, title: { "en" => filename }, file:, attached_to: proposal, weight: 0) }
      let(:filename) { "city.jpeg" }
      let(:file) { Decidim::Dev.test_file(filename, "image/jpeg") }

      let!(:document) { create(:attachment, title: { "en" => filename2 }, file: file2, attached_to: proposal, weight: 1) }
      let(:filename2) { "city2.jpeg" }
      let(:file2) { Decidim::Dev.test_file(filename2, "image/jpeg") }

      before do
        login_as user, scope: :user
        visit_component
        click_link_or_button translated(proposal.title), match: :first
      end

      it "attachments are in different sections" do
        click_link_or_button "Edit proposal"
        page.execute_script "window.scrollBy(0,10000)"
        expect(page).to have_css(".attachment-details[data-filename='#{filename}']")
        expect(page).to have_css(".attachment-details[data-filename='#{filename2}']")
      end
    end

    context "and category and scope are required" do
      let!(:settings) { { scopes_enabled: true, require_category: true, require_scope: true } }
      let(:category) { create(:category, participatory_space: participatory_process) }
      let!(:category_bis) { create(:category, participatory_space: participatory_process) }
      let(:parent_scope) { create(:scope, organization:) }
      let(:scope) { create(:subscope, parent: parent_scope) }
      let(:proposal) { create(:proposal, users: [user], component:, body: proposal_body, title: proposal_title, decidim_scope_id: scope.id, category:) }

      before do
        login_as user, scope: :user
        visit_component
        click_link_or_button translated(proposal.title), match: :first
      end

      it "can edit proposal without changing category and scope" do
        click_link_or_button "Edit proposal"
        fill_in :proposal_body, with: "This is my new body"
        click_link_or_button "Send"
        expect(page).to have_content("Proposal successfully updated.")
        expect(page).to have_content("This is my new body")
      end

      it "can edit proposal by changing scope" do
        click_link_or_button "Edit proposal"
        select parent_scope.name["en"], from: :proposal_scope_id
        click_link_or_button "Send"
        expect(page).to have_content("Proposal successfully updated.")
      end

      it "can edit proposal by changing category" do
        click_link_or_button "Edit proposal"
        select category_bis.name["en"], from: :proposal_category_id
        click_link_or_button "Send"
        expect(page).to have_content("Proposal successfully updated.")
      end

      it "cannot edit proposal without a category" do
        click_link_or_button "Edit proposal"
        select "Please select a category", from: :proposal_category_id
        click_link_or_button "Send"
        expect(page).to have_content("There is an error in this field")
      end

      it "cannot edit proposal without a scope" do
        click_link_or_button "Edit proposal"
        select "Select a scope", from: :proposal_scope_id
        click_link_or_button "Send"
        expect(page).to have_content("There is an error in this field")
      end
    end
  end
end
