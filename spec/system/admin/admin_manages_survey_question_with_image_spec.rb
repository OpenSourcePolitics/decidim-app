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

    let(:description_with_image) do
      {
        en:
          <<~HTML
            <p><img src="http://mon_image.png"></p>
          HTML
      }
    end

    let!(:question) { create(:questionnaire_question, description: description_with_image, questionnaire: questionnaire) }

    it "after save, it renders image in description with hidden input value filled" do
      Capybara.ignore_hidden_elements = false
      visit questionnaire_edit_path
      click_button "Save"
      click_button "Expand all"
      within "#questionnaire_question_#{question.id}-field" do
        within "#questionnaire_question_#{question.id}-description-panel-0" do
          description = find(".ql-editor p")
          expect(description).to have_xpath('//img[@src="http://mon_image.png"]')
          input = page.find("#questionnaire_questions_#{question.id}_description_en")
          expect(input.value).to eq('<p><img src="http://mon_image.png"></p>')
        end
      end
    end
  end

  def questionnaire_edit_path
    manage_component_path(component)
  end
end
