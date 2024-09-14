# frozen_string_literal: true

require "spec_helper"

describe "Admin adds display condition to template's questionniaire question", type: :system do
  let!(:organization) { create(:organization) }
  let!(:user) { create(:user, :admin, :confirmed, organization: organization) }
  let(:template) { create(:questionnaire_template, organization: organization) }
  let(:matrix_rows) { Array.new(2) { { "body" => Decidim::Faker::Localized.sentence } } }
  let(:answer_options) { Array.new(2) { { "body" => Decidim::Faker::Localized.sentence } } }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  it "adds display condition to questionnaire question" do
    questionnaire = template.templatable
    question_one = create(:questionnaire_question, mandatory: true, question_type: "matrix_single", rows: matrix_rows, options: answer_options, questionnaire: questionnaire)
    question_two = create(:questionnaire_question, :with_answer_options, questionnaire: questionnaire)

    visit decidim_admin_templates.edit_questionnaire_path(template.id)
    # expand question two
    click_on("[data-toggle^=questionnaire_question_#{question_two.id}-question-card]")
    within "#questionnaire_question_#{question_two.id}-field" do
      # add display condition
      click_on(".add-display-condition")
      # select question
      select translated(question_one.body), from: "#questionnaire_questions_#{question_two.id}_display_conditions_questionnaire-display-condition-id_decidim_condition_question_id"
      # select equal
      select "Equal", from: "#questionnaire_questions_#{question_two.id}_display_conditions_questionnaire-display-condition-id_condition_type"
    end
    # validate we have the 2 answer options from question one
    expect(page).to include(translated(question_one.answer_options.first.body))
    expect(page).to include(translated(question_one.answer_options.last.body))
  end
end
