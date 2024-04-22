# frozen_string_literal: true

shared_context "with scopes" do
  let(:parent_scope) { create(:scope, organization: organization) }
  let!(:subscopes) { create_list(:scope, 3, parent: parent_scope, organization: organization) }
  let!(:first_postals) do
    [].tap do |postals|
      5.times do |i|
        code = (10_000 + i).to_s
        postals << create(:scope, name: { en: code }, code: "FIRST_#{code}", parent: subscopes[0], organization: organization)
      end
    end
  end
  let!(:second_postals) do
    [].tap do |postals|
      7.times do |i|
        code = (10_010 + i).to_s
        postals << create(:scope, name: { en: code }, code: "SECOND_#{code}", parent: subscopes[1], organization: organization)
      end
    end
  end
  let!(:third_postals) do
    [].tap do |postals|
      8.times do |i|
        code = (10_020 + i).to_s
        postals << create(:scope, name: { en: code }, code: "THIRD_#{code}", parent: subscopes[2], organization: organization)
      end
    end
  end
end

shared_context "with user data" do
  let!(:user_data) { create(:user_data, component: component, user: user) }
end

shared_context "with scoped budgets" do
  include_context "with scopes"

  let(:organization) { create(:organization) }
  let(:component) { create(:budgets_component, settings: component_settings, organization: organization) }
  let(:component_settings) { { scopes_enabled: true, scope_id: parent_scope.id } }

  let(:budgets) { create_list(:budget, 3, component: component, total_budget: 100_000) }
  let!(:first_projects_set) { create_list(:project, projects_count, budget: budgets[0], budget_amount: 25_000) }
  let!(:second_projects_set) { create_list(:project, projects_count, budget: budgets[1], budget_amount: 25_000) }
  let!(:last_projects_set) { create_list(:project, projects_count, budget: budgets[2], budget_amount: 25_000) }

  before do
    # We update the description to be less than the truncation limit. To test the truncation, we update those in tests.
    attach_images(budgets)
    budgets[0].update!(scope: parent_scope, description: { en: "<p>Eius officiis expedita. 55</p>" })
    budgets[1].update!(scope: subscopes[0], description: { en: "<p>Eius officiis expedita. 56</p>" })
    budgets[2].update!(scope: subscopes[1])
  end

  private

  def attach_images(budgets)
    city_files = ["city.jpeg", "city2.jpeg", "city3.jpeg"]
    budgets.each_with_index do |budget, ind|
      budget.update(main_image: ActiveStorage::Blob.create_and_upload!(
        io: File.open(Decidim::Dev.asset(city_files[ind])),
        filename: city_files[ind],
        content_type: "image/jpeg"
      ))
    end
  end
end

shared_context "with single scoped budget" do
  include_context "with scopes"

  let(:organization) { create(:organization) }
  let(:component) { create(:budgets_component, settings: component_settings, organization: organization) }
  let(:component_settings) { { scopes_enabled: true, scope_id: parent_scope.id } }

  let!(:budget) { create(:budget, component: component, total_budget: 100_000) }
  let!(:projects_set) { create_list(:project, 3, budget: budget, budget_amount: 25_000) }

  before do
    budget.update!(scope: subscopes[0], description: { en: "<p>Eius officiis expedita. 55</p>" })
  end
end

shared_context "with zip_code workflow" do
  let!(:component) do
    create(
      :budgets_component,
      settings: component_settings.merge(workflow: "zip_code"),
      organization: organization
    )
  end
end

shared_context "with a survey" do
  let!(:participatory_space) { component.participatory_space }
  let!(:surveys_component) { create(:surveys_component, :published, participatory_space: participatory_space) }
  let!(:survey) { create(:survey, component: surveys_component) }
  let!(:questionnaire) { create(:questionnaire, questionnaire_for: survey) }
end
