# frozen_string_literal: true

require "spec_helper"

describe "Sorting projects", type: :system do
  include_context "with a component"
  let(:manifest_name) { "budgets" }

  let(:organization) { create :organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:project) { projects.first }

  let!(:component) do
    create(:budgets_component,
           :with_vote_threshold_percent,
           :with_show_votes_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  let(:budget) { create :budget, component: component }
  let!(:project1) { create(:project, budget: budget, budget_amount: 25_000_000) }
  let!(:project2) { create(:project, budget: budget, budget_amount: 70_000_000) }

  before do
    login_as user, scope: :user
    visit_budget
  end

  shared_examples "ordering projects by selected option" do |selected_option|
    before do
      visit_budget
      within ".order-by" do
        expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random order")
        page.find("a", text: "Random order").click
        click_link(selected_option)
      end
    end

    it "lists the projects ordered by selected option" do
      # expect(page).to have_selector("#projects li.is-dropdown-submenu-parent a", text: selected_option)
      within "#projects li.is-dropdown-submenu-parent a" do
        expect(page).to have_no_content("Random order", wait: 20)
        expect(page).to have_content(selected_option)
      end

      expect(page).to have_selector("#projects .budget-list .budget-list__item:first-child", text: translated(first_project.title))
      expect(page).to have_selector("#projects .budget-list .budget-list__item:last-child", text: translated(last_project.title))
    end
  end

  context "when ordering by highest cost" do
    it_behaves_like "ordering projects by selected option", "Highest cost" do
      let(:first_project) { project2 }
      let(:last_project) { project1 }
    end
  end

  context "when ordering by lowest cost" do
    it_behaves_like "ordering projects by selected option", "Lowest cost" do
      let(:first_project) { project1 }
      let(:last_project) { project2 }
    end
  end

  context "when ordering by most voted" do
    context "when less than the page can display" do
      it_behaves_like "ordering projects by selected option", "Most voted" do
        let(:first_project) { project2 }
        let(:last_project) { project1 }
        let(:order1) do
          order = create(:order, user: user, budget: budget)
          order.projects << first_project
          order.checked_out_at = Time.current
          order.save!
          order
        end
      end
    end

    context "with more than the page can display" do
      let!(:first_project) { project1 }
      let!(:last_project) { project2 }
      let!(:other_projects) { create_list(:project, 20, budget: budget, budget_amount: 50_000_000) }
      let!(:user2) { create :user, :confirmed, organization: organization }
      let!(:user3) { create :user, :confirmed, organization: organization }
      let(:order1) do
        order = create(:order, user: user, budget: budget)
        order.projects << first_project
        order.projects << last_project
        order.checked_out_at = Time.current
        order.save!
        order
      end
      let(:order2) do
        order = create(:order, user: user2, budget: budget)
        order.projects << first_project
        order.projects << other_projects[0]
        order.checked_out_at = Time.current
        order.save!
        order
      end
      let(:order3) do
        order = create(:order, user: user3, budget: budget)
        order.projects << last_project
        order.projects << first_project
        order.checked_out_at = Time.current
        order.save!
        order
      end

      before do
        order1.checked_out_at = 1.hour.ago
        order2.checked_out_at = 1.hour.ago
        order3.checked_out_at = 1.hour.ago
        visit_budget
        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random order")
          page.find("a", text: "Random order").click
          click_link("Most voted")
        end
      end

      it "lists the projects ordered by selected option" do
        within "#projects li.is-dropdown-submenu-parent a" do
          expect(page).to have_no_content("Random order", wait: 20)
          expect(page).to have_content("Most voted")
        end

        expect(page).to have_selector("#projects .budget-list .budget-list__item:first-child", text: translated(first_project.title))
        expect(page).to have_selector("#projects .budget-list .budget-list__item:nth-child(2)", text: translated(last_project.title))
      end
    end
  end

  describe "when the voting is finished" do
    let!(:component) do
      create(
        :budgets_component,
        :with_voting_finished,
        manifest: manifest,
        participatory_space: participatory_process
      )
    end
    let!(:project1) { create(:project, :selected, budget: budget, budget_amount: 25_000_000) }
    let!(:project2) { create(:project, :selected, budget: budget, budget_amount: 77_000_000) }

    context "when ordering by most votes" do
      before do
        order = build :order, budget: budget
        create :line_item, order: order, project: project2
        order = Decidim::Budgets::Order.last
        order.checked_out_at = Time.zone.now
        order.save
      end

      it "automatically sorts by votes" do
        visit_budget

        within "#projects li.is-dropdown-submenu-parent a" do
          expect(page).to have_content("Most voted")
        end

        expect(page).to have_selector("#projects .budget-list .budget-list__item:first-child", text: translated(project2.title))
        expect(page).to have_selector("#projects .budget-list .budget-list__item:last-child", text: translated(project1.title))
      end
    end
  end

  def visit_budget
    page.visit Decidim::EngineRouter.main_proxy(component).budget_projects_path(budget)
  end
end
