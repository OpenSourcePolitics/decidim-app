# frozen_string_literal: true

require "spec_helper"

describe "Budgets view", type: :system do
  let(:decidim_half_signup_admin) { Decidim::HalfSignup::AdminEngine.routes.url_helpers }
  let(:projects_count) { 1 }
  let(:decidim_budgets) { Decidim::EngineRouter.main_proxy(component) }
  let(:user) { create(:user, :confirmed, organization: organization) }

  before do
    switch_to_host(organization.host)
  end

  context "with multiple budgets" do
    include_context "with scoped budgets"

    context "when not signed in" do
      before { visit decidim_budgets.budgets_path }

      it "shows the normal layout" do
        expect(page).to have_link(translated(budgets.first.title), href: decidim_budgets.budget_path(budgets.first))
        expect(page).to have_selector("a", text: /show/i, count: 3)
        expect(page).to have_content("€100,000")
      end

      # customizations for Half signup x budget booth
      context "when half signup sms is enabled" do
        let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_sms_signup: true) }

        before do
          visit decidim_budgets.budget_path(budgets.first)
        end

        it "redirects user to the half signup sms page" do
          find("a.hollow:nth-child(1)").click
          expect(page).to have_content("Please enter your phone number:")
        end

        context "when user fills half signup sms form" do
          before do
            find("a.hollow:nth-child(1)").click
            fill_in :sms_auth_phone_number, with: "4578878784"
            click_button "Send the code"
          end

          it "redirects user to the half signup sms page" do
            expect(page).to have_content("You should have received the code")
            code = page.find("#hint").text
            fill_in_code(code, "digit")
            click_button "Verify"
            click_button "I agree with these terms"
            expect(page).to have_content("You are now in the voting booth")
          end
        end
      end
    end

    context "when signed in" do
      before { sign_in user, scope: :user }

      # customizations for Half signup x budget booth
      context "when half signup sms is enabled" do
        let!(:auth_settings) { create(:auth_setting, organization: organization, enable_partial_sms_signup: true) }

        before do
          visit decidim_budgets.budget_path(budgets.first)
        end

        context "and user has no phone_number" do
          it "redirects user to the half signup sms page" do
            find("button.hollow:nth-child(1)").click
            expect(page).to have_content("Sign In")
            expect(page).to have_content("Please enter your phone number:")
          end

          context "when user fills half signup sms form" do
            before do
              find("button.hollow:nth-child(1)").click
              fill_in :sms_auth_phone_number, with: "4578878784"
              click_button "Send the code"
            end

            it "redirects user to the half signup sms page" do
              expect(page).to have_content("You should have received the code")
              code = page.find("#hint").text
              fill_in_code(code, "digit")
              click_button "Verify"
              expect(page).to have_content("You are now in the voting booth")
            end
          end
        end

        context "and user has phone_number" do
          let(:user) { create(:user, :confirmed, organization: organization, phone_number: "4578878784", phone_country: "US") }

          it "redirects user to the budget booth" do
            find("button.hollow:nth-child(1)").click
            expect(page).to have_content("You are now in the voting booth")
          end
        end
      end
    end

    context "when workflow" do
      include_context "with zip_code workflow"

      context "when not signed in" do
        before { visit decidim_budgets.budgets_path }

        it_behaves_like "ensure user sign in"
      end

      context "when signed in" do
        before { sign_in user, scope: :user }

        context "when no zip code" do
          before { visit decidim_budgets.budgets_path }

          it "redirects user to zipcode entering path" do
            expect(page).to have_current_path(decidim_budgets.new_zip_code_path)
          end
        end

        context "with user zip_code exist" do
          let!(:user_data) { create(:user_data, component: component, user: user, metadata: { zip_code: "dummy_1234" }) }

          context "when no budgets to vote" do
            before { visit decidim_budgets.budgets_path }

            it "renders budgets page" do
              expect(page).to have_current_path(decidim_budgets.budgets_path)
              expect(page).to have_content "No budgets were found based on your ZIP code. You can change your ZIP code if it's not correct, or you can search again later."
            end
          end

          context "when budgets to vote" do
            let(:first_budget) { budgets.first }
            let(:second_budget) { budgets.second }
            let(:landing_page_content) { Decidim::Faker::Localized.sentence(word_count: 5) }

            before do
              user_data.update!(metadata: { zip_code: "10004" })
              visit decidim_budgets.budgets_path
            end

            it "renders the budgets page and budgets" do
              expect(page).to have_current_path(decidim_budgets.budgets_path)
              expect(page).to have_content "You are now in the voting booth."
              within "#budgets" do
                expect(page).to have_css(".card.card--list.budget-list", count: 2)
                expect(page).to have_selector("a", text: "More info", count: 2)
                expect(page).to have_link(text: /TAKE PART/, href: decidim_budgets.budget_voting_index_path(first_budget))
                expect(page).to have_link(text: /TAKE PART/, href: decidim_budgets.budget_voting_index_path(second_budget))
                expect(page).to have_link(translated(first_budget.title), href: decidim_budgets.budget_voting_index_path(budgets.first))
                expect(page).to have_link(translated(second_budget.title), href: decidim_budgets.budget_voting_index_path(second_budget))
                expect(page).to have_content("Eius officiis expedita. 55")
                expect(page).to have_content("Eius officiis expedita. 56")
              end
              expect(page).to have_no_css(".callout.warning.font-customizer")
              expect(page).to have_button("Cancel voting")
              click_button "Cancel voting"
              within ".small.reveal.confirm-reveal" do
                expect(page).to have_content("Are you sure you want to exit the voting booth?")
                click_link "OK"
              end
              expect(page).to have_link(href: "/")
            end

            context "when description is long" do
              before do
                first_budget.update!(description: { en: "<p>Lorem ipsum dolor sit amet, <em>consectetur</em> adipiscing elit. <b>Fus</b>. ultricies lacus vel dui vestibulum, eu aliquam libero convallis. Donec vitae ligula velit</p" })
                second_budget.update!(description: { en: "<p>Fooba ligul dolor sit amet, <em>consectetur</em> adipiscing elit. <b>Fus</b>. ultricies lacus vel dui vestibulum, eu aliquam libero convallis. Donec vitae ligula velit</p" })
                visit decidim_budgets.budgets_path
              end

              it "truncates the budgets description" do
                within "#budgets" do
                  expect(page).to have_content("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fus. ult...")
                  expect(page).to have_content("Fooba ligul dolor sit amet, consectetur adipiscing elit. Fus. ult...")
                end
              end
            end

            context "with landing page content" do
              let(:landing_page_content) { Decidim::Faker::Localized.sentence(word_count: 5) }

              before do
                component.update(settings: component_settings.merge(workflow: "zip_code", landing_page_content: landing_page_content))
                visit current_path
              end

              it "renders callout message" do
                expect(page).to have_css(".callout.warning.font-customizer")
                within ".callout.warning.font-customizer" do
                  expect(page).to have_content(translated(landing_page_content))
                end
              end
            end

            context "with cancel voting booth url" do
              include_context "with a survey"
              before do
                component.update(settings: component_settings.merge(workflow: "zip_code", vote_cancel_url: main_component_path(surveys_component)))
                visit current_path
              end

              it "redirects to correct url" do
                expect(page).to have_button("Cancel voting")
                click_button "Cancel voting"
                within ".small.reveal.confirm-reveal" do
                  expect(page).to have_content("Are you sure you want to exit the voting booth?")
                  click_link "OK"
                end
                expect(page).to have_current_path(main_component_path(surveys_component))
              end
            end

            describe "vote all budgets" do
              # We add another budget to the list of budgets where use is eligible to vote
              let!(:extra_budget) { create(:budget, component: component, scope: extra_scope, total_budget: 100_000) }
              let!(:extra_scope) { create(:scope, parent: parent_scope, organization: organization) }
              let!(:extra_postal) { create(:scope, name: { en: "10004" }, code: "EXTRA_10004", parent: extra_scope, organization: organization) }
              let!(:extra_project) { create(:project, budget: extra_budget, budget_amount: 75_000) }

              before do
                component.update(settings: component_settings.merge(workflow: "zip_code", vote_threshold_percent: 0))
              end

              it "shows all of the budgets after completing voting when maximum_budgets_to_vote_on not set" do
                [extra_budget, first_budget, second_budget].each do |bdg|
                  create_order(bdg)
                end
                visit current_path
                expect(page).to have_selector("div.card.card--list.budget-list", count: 3)
              end

              it "shows only voted budgets when maximum_budgets_to_vote_on is set" do
                component.update(settings: component_settings.merge(workflow: "zip_code", vote_threshold_percent: 0, maximum_budgets_to_vote_on: 2))
                [extra_budget, first_budget].each do |bdg|
                  create_order(bdg)
                end
                visit current_path
                expect(page).to have_selector("div.card.card--list.budget-list", count: 2)
              end
            end

            describe "votes popup" do
              before do
                first_budget.projects.first.update!(budget_amount: 75_000)
                create_order(first_budget)
                visit current_path
              end

              it "shows the popups" do
                within "div.card.card--list.budget-list", match: :first do
                  expect(page).to have_link("Show my vote")
                  click_link "Show my vote"
                end
                expect(page).to have_selector("div", id: "budget-votes-#{first_budget.id}")
                order = Decidim::Budgets::Order.last
                project = order.projects.first
                within "#budget-votes-#{first_budget.id}" do
                  expect(page).to have_content("Your vote in #{translated(first_budget.title)}")
                  expect(page).to have_content("These are the projects you have chosen to be part of the budget.")
                  expect(page).to have_content(translated(project.title))
                  click_button "OK"
                end
                expect(page).to have_no_selector("div", id: "budget-votes-#{first_budget.id}")
              end
            end
          end
        end
      end
    end
  end

  context "with single budget" do
    include_context "with single scoped budget"
    let!(:user_data) { create(:user_data, component: component, user: user, metadata: { zip_code: "10004" }) }

    before do
      sign_in user
      component.update(settings: component_settings.merge(workflow: "zip_code"))
      visit decidim_budgets.budgets_path
    end

    it "shows the budgets list when visit budgets list" do
      expect(page).to have_current_path(decidim_budgets.budgets_path)
      expect(page).to have_content "You are now in the voting booth."
      within "#budgets" do
        expect(page).to have_css(".card.card--list.budget-list", count: 1)
        expect(page).to have_selector("a", text: "More info", count: 1)
        expect(page).to have_link(text: /TAKE PART/, href: decidim_budgets.budget_voting_index_path(budget))
        expect(page).to have_link(translated(budget.title), href: decidim_budgets.budget_voting_index_path(budget))
        expect(page).to have_content("Eius officiis expedita. 55")
      end
    end

    it "does not show the budgets header in voting booth when go to the booth" do
      visit decidim_budgets.budget_voting_index_path(budget)
      expect(page).to have_current_path(decidim_budgets.budget_voting_index_path(budget))
      expect(page).not_to have_content("Based on your ZIP code - 10004. Not the right one?")
      expect(page).not_to have_link("Change it here", href: decidim_budgets.new_zip_code_path)
    end
  end

  private

  def decidim_budgets
    Decidim::EngineRouter.main_proxy(component)
  end

  def budget_path(budget)
    decidim_budgets.budget_path(budget.id)
  end

  def create_order(budget)
    order = create(:order, user: user, budget: budget)
    order.projects << budget.projects.first
    order.checked_out_at = Time.current
    order.save!
  end
end
