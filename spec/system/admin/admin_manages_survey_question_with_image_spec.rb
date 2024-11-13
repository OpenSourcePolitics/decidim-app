# frozen_string_literal: true

require "spec_helper"

describe "Admin manages survey question with image", type: :system do
  let(:manifest_name) { "surveys" }
  let!(:component) do
    create(:component,
           manifest: manifest,
           participatory_space: participatory_space,
           published_at: nil)
  end
  let!(:questionnaire) { create(:questionnaire) }
  let!(:survey) { create :survey, component: component, questionnaire: questionnaire }

  include_context "when managing a component as an admin"

  context "when survey is not published" do
    before do
      component.unpublish!
    end

    let(:image_url) { "https://unsplash.com/fr/photos/une-trainee-detoiles-est-vue-dans-le-ciel-au-dessus-de-locean-pjHseB_JLpg" }
    let(:router) { Decidim::EngineRouter.main_proxy(component) }
    let(:description_with_image) do
      {
        "en" => "<p><img src=\"#{image_url}\"</p>",
        "ca" => "<p><img src=\"#{image_url}\"</p>",
        "es" => "<p><img src=\"#{image_url}\"</p>"
      }
    end
    let!(:question) { create(:questionnaire_question, description: description_with_image, questionnaire: questionnaire) }

    it "after save, it renders description with hidden input value filled" do
      Capybara.ignore_hidden_elements = false
      visit questionnaire_edit_path
      click_button "Expand all"
      expect(page).to have_selector("img[src='#{image_url}']")
      click_button "Save"
      click_button "Expand all"
      expect(page).to have_selector("img[src='#{image_url}']")
      within "#questionnaire_question_#{question.id}-field" do
        within "#questionnaire_question_#{question.id}-description-panel-0" do
          input = page.find("#questionnaire_questions_#{question.id}_description_en")
          expect(input.value).to eq("<p><img src=\"#{image_url}\"></p>")
        end
      end
    end
  end

  def questionnaire_edit_path
    manage_component_path(component)
  end
end
