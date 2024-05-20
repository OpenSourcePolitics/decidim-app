# frozen_string_literal: true

require "spec_helper"

module Decidim
  module BudgetsImporter
    module Admin
      describe ImportProject do
        describe "call" do
          let(:organization) { create :organization }
          let(:current_user) { create :user, :admin, :confirmed, organization: organization }
          let(:participatory_process) { create :participatory_process, organization: organization }
          let(:current_component) { create(:component, manifest_name: :budgets, participatory_space: participatory_process) }
          let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
          let!(:proposal) { create(:proposal, id: 1, component: proposal_component) }
          let!(:proposal2) { create(:proposal, id: 2, component: proposal_component) }
          let(:budget) { create :budget, component: current_component }
          let!(:category) { create(:category, id: 1, participatory_space: current_component.participatory_space) }
          let(:document) { upload_test_file(fixture_test_file(filename, mime_type)) }
          let(:filename) { "projects-import.csv" }
          let(:mime_type) { "text/csv" }
          let(:blob) { ActiveStorage::Blob.find_signed(document) }
          let(:blob_file_path) { ActiveStorage::Blob.service.path_for(blob.key) }
          let(:valid) { true }
          let!(:form) do
            double(
              valid?: valid,
              invalid?: !valid,
              current_component: current_component,
              current_user: current_user,
              budget: budget,
              blob: blob,
              file_path: blob_file_path
            )
          end

          let(:command) { described_class.new(form) }

          shared_examples_for "saves imported projects" do
            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates the projects" do
              expect do
                command.call
              end.to change { Decidim::Budgets::Project.where(budget: budget).count }.by(2)
            end

            it "broadcast_registry is empty" do
              cmd = command.call
              expect(cmd.broadcast_registry.registry).to be_empty
              expect(cmd.broadcast_registry).not_to be_invalid
            end
          end

          shared_examples_for "does not save imported projects" do
            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "does not create the projects" do
              expect do
                command.call
              end.not_to(change { Decidim::Budgets::Project.where(budget: budget).count })
            end

            it "broadcast_registry is invalid" do
              cmd = command.call

              if valid
                expect(cmd.broadcast_registry.registry).not_to be_empty
                expect(cmd.broadcast_registry).to be_invalid
              else
                expect(cmd.broadcast_registry.registry).to be_empty
                expect(cmd.broadcast_registry).not_to be_invalid
              end
            end
          end

          it_behaves_like "saves imported projects"

          describe "when document is JSON" do
            let(:filename) { "projects-import.json" }
            let(:mime_type) { "application/json" }

            it_behaves_like "saves imported projects"
          end

          describe "when document is XLSX" do
            let(:filename) { "projects-import.xlsx" }
            let(:mime_type) { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }

            it_behaves_like "saves imported projects"
          end

          describe "when the form is invalid" do
            let(:valid) { false }

            it_behaves_like "does not save imported projects"
          end

          context "when category ID does not exist" do
            let(:category) { create(:category) }

            it_behaves_like "does not save imported projects"
          end

          context "when related proposal ID does not exist in participatory space" do
            let!(:proposal) { create(:proposal, id: 1) }

            it_behaves_like "does not save imported projects"
          end

          context "when one of related proposals ID does not exist" do
            let!(:proposal) { create(:proposal, id: 10, component: proposal_component) }

            it_behaves_like "does not save imported projects"
          end
        end
      end
    end
  end
end
