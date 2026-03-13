# frozen_string_literal: true

require "spec_helper"

describe "Proposals" do
  include_context "with a component"
  let(:manifest_name) { "proposals" }
  let!(:user) { create(:user, :confirmed, organization:) }
  let(:images_editor) { false }
  let!(:allow_images_in_editors) { create(:awesome_config, organization:, var: :allow_images_in_editors, value: images_editor) }
  let!(:component) do
    create(:proposal_component,
           :with_creation_enabled,
           manifest:,
           participatory_space: participatory_process,
           settings: { new_proposal_body_template: body_template })
  end
  let(:body_template) do
    { "en" => "<p>This test has <strong>many</strong> characters </p>" }
  end

  context "when creating a new proposal" do
    before do
      login_as user, scope: :user
      visit_component
    end

    context "when rich text editor is enabled for participants but images in rich text are not allowed" do
      before do
        organization.update(rich_text_editor_in_public_views: true)
        click_on "New proposal"
      end

      it_behaves_like "having a rich text editor", "new_proposal", "basic"

      it "has helper character counter" do
        within "form.new_proposal" do
          within ".editor .input-character-counter__text" do
            expect(page).to have_content("At least 15 characters", count: 1)
          end
        end
      end

      it "displays the text with rich text in the input body" do
        within "form.new_proposal" do
          within ".editor-input" do
            expect(find("p").text).to eq("This test has many characters")
            expect(find("strong").text).to eq("many")
          end
        end
      end

      it "does not display a text above the editor to avoid special characters in image name" do
        within "div.editor" do
          expect(page).to have_no_content("If you upload an image, the name of the file must not contain special characters (space, accent, parenthesis...).")
        end
      end

      context "and images are allowed in rich text" do
        let(:images_editor) { true }
        let(:editor_selector) { ".editor-input" }
        let(:image) { Decidim::Dev.test_file("city.jpeg", "image/jpeg") }

        it "displays a text above the editor to avoid special characters in image name" do
          within "div.editor" do
            expect(page).to have_content("If you upload an image, the name of the file must not contain special characters (space, accent, parenthesis...).")
          end
        end

        it "displays a text in the upload modal to avoid special characters in image name" do
          find('.editor-toolbar-control[data-editor-type="image"]').click

          within "div.upload-modal__text" do
            expect(page).to have_content("No special characters in image name.")
          end
        end
      end
    end

    describe "validating the form" do
      before do
        click_on "New proposal"
      end

      context "when focus shifts to body" do
        it "displays error when title is empty" do
          fill_in :proposal_title, with: " "
          find_by_id("proposal_body").click

          expect(page).to have_css(".form-error.is-visible", text: "There is an error in this field.")
        end

        it "displays error when title is invalid" do
          fill_in :proposal_title, with: "invalid-title"
          find_by_id("proposal_body").click

          expect(page).to have_css(".form-error.is-visible", text: "There is an error in this field")
        end
      end

      context "when focus remains on title" do
        it "does not display error when title is empty" do
          fill_in :proposal_title, with: " "
          find_by_id("proposal_title").click

          expect(page).to have_no_css(".form-error.is-visible", text: "There is an error in this field.")
        end

        it "does not display error when title is invalid" do
          fill_in :proposal_title, with: "invalid-title"
          find_by_id("proposal_title").click

          expect(page).to have_no_css(".form-error.is-visible", text: "There is an error in this field")
        end
      end
    end
  end
end
