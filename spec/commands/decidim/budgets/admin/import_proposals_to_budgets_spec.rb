# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Budgets
    module Admin
      describe ImportProposalsToBudgets do
        describe "call" do
          let!(:proposal) { create(:proposal, :accepted) }
          let!(:first_proposal) { create(:proposal, :accepted) }
          let!(:second_proposal) { create(:proposal, :accepted) }
          let!(:current_component) do
            create(
              :component,
              manifest_name: "budgets",
              participatory_space: proposal.component.participatory_space
            )
          end
          let(:budget) { create(:budget, component: current_component) }
          let!(:current_user) { create(:user, :admin, organization: current_component.participatory_space.organization) }
          let!(:organization) { current_component.participatory_space.organization }
          let!(:parent_scope) { create(:scope, organization: organization) }
          let!(:scope_one) { create(:scope, organization: organization, parent: parent_scope) }
          let!(:scope_two) { create(:scope, organization: organization, parent: parent_scope) }
          let!(:scope) { parent_scope }
          let!(:form) do
            double(
              ProjectImportProposalsForm,
              origin_component: proposal.component,
              current_component: current_component,
              current_user: current_user,
              import_all_accepted_proposals: true,
              scope_id: scope.id,
              budget: budget,
              valid?: true
            )
          end
          let(:default_budget) { 1000 }
          let(:command) { described_class.new(form) }

          context "when scope is enabled in budget config and equal to parent_scope" do
            context "and parent_scope is selected in the form" do
              before do
                allow_any_instance_of(Decidim::Budgets::Admin::ImportProposalsToBudgets).to receive(:selected_scope_id).and_return(parent_scope.id)
              end

              context "and parent_scope has no children" do
                it "creates one project from parent proposal" do
                  proposal.update(decidim_scope_id: parent_scope.id)
                  expect do
                    command.call
                  end.to change { Project.where(budget: budget).count }.by(1)
                  expect(Project.last.title).to eq(proposal.title)
                end
              end

              context "and parent_scope has children" do
                it "creates projects from children proposals and parent proposal" do
                  proposal.update(decidim_scope_id: parent_scope.id)
                  first_proposal.update(decidim_scope_id: scope_one.id, component: proposal.component)
                  second_proposal.update(decidim_scope_id: scope_two.id, component: proposal.component)
                  expect do
                    command.call
                  end.to change { Project.where(budget: budget).count }.by(3)
                  expect(Project.last(3).map(&:title)).to include(proposal.title, first_proposal.title, second_proposal.title)
                end
              end
            end

            context "when child_scope is selected in the form" do
              before do
                allow_any_instance_of(Decidim::Budgets::Admin::ImportProposalsToBudgets).to receive(:selected_scope_id).and_return(scope_one.id)
              end

              it "creates one project from child proposal" do
                proposal.update(decidim_scope_id: parent_scope.id)
                first_proposal.update(decidim_scope_id: scope_one.id, component: proposal.component)
                expect do
                  command.call
                end.to change { Project.where(budget: budget).count }.by(1)
                expect(Project.last.title).to eq(first_proposal.title)
              end
            end
          end

          context "when scope is not enabled in budget config" do
            before do
              allow_any_instance_of(Decidim::Budgets::Admin::ImportProposalsToBudgets).to receive(:selected_scope_id).and_return(nil)
            end

            it "creates as many projects as accepted proposals" do
              proposal.update(decidim_scope_id: parent_scope.id)
              first_proposal.update(decidim_scope_id: scope_one.id, component: proposal.component)
              expect do
                command.call
              end.to change { Project.where(budget: budget).count }.by(2)
              expect(Project.last(2).map(&:title)).to include(proposal.title, first_proposal.title)
            end
          end
        end
      end
    end
  end
end
