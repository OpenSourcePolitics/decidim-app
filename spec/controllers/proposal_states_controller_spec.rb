# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    module Admin
      describe ProposalStatesController do
        routes { Decidim::Proposals::AdminEngine.routes }

        let(:organization) { create(:organization) }
        let(:initiative) { create(:initiative, organization:) }
        let(:component) { create(:proposal_component, participatory_space: initiative) }
        let(:user) { create(:user, :admin, :confirmed, organization:) }

        def route_params(extra_params = {})
          { component_id: component.id, initiative_slug: initiative.slug }.merge(extra_params)
        end

        before do
          request.env["decidim.current_organization"] = organization
          request.env["decidim.current_participatory_space"] = initiative
          request.env["decidim.current_component"] = component
          sign_in user
        end

        describe "GET #index" do
          it "renders successfully" do
            get :index, params: route_params
            expect(response).to be_successful
          end

          context "with multiple proposal states" do
            before do
              ProposalState.where(component:).destroy_all
              create(:proposal_state, component:, weight: 10)
              create(:proposal_state, component:, weight: 5)
              create(:proposal_state, component:, weight: 15)
            end

            it "orders proposal states by weight" do
              get :index, params: route_params
              weights = controller.send(:proposal_states).map(&:weight)
              expect(weights).to eq([5, 10, 15])
            end
          end

          context "with proposal states from different components" do
            let(:other_component) { create(:proposal_component, participatory_space: initiative) }

            before do
              ProposalState.where(component:).destroy_all
              create(:proposal_state, component:, weight: 1)
              create(:proposal_state, component: other_component, weight: 2)
            end

            it "only shows proposal states from current component" do
              get :index, params: route_params
              states = controller.send(:proposal_states)
              expect(states.count).to eq(1)
              expect(states.map(&:component)).to all(eq(component))
            end
          end

          context "with pagination" do
            before do
              ProposalState.where(component:).destroy_all
              30.times { |i| create(:proposal_state, component:, weight: i + 1) }
            end

            it "paginates the results" do
              get :index, params: route_params
              states = controller.send(:proposal_states)
              expect(states).to respond_to(:total_pages)
              expect(states.total_pages).to be > 1
            end
          end
        end

        describe "GET #new" do
          it "renders successfully" do
            get :new, params: route_params
            expect(response).to be_successful
          end

          it "initializes a new form" do
            get :new, params: route_params
            expect(assigns(:form)).to be_a(Decidim::Proposals::Admin::ProposalStateForm)
          end
        end

        describe "POST #create" do
          let(:valid_params) do
            route_params(
              proposal_state: {
                title: { en: "New State" },
                announcement_title: { en: "Announcement" }
              }
            )
          end

          it "creates a new proposal state" do
            expect do
              post :create, params: valid_params
            end.to change(ProposalState, :count).by(1)
          end

          it "redirects to index on success" do
            post :create, params: valid_params
            expect(response).to redirect_to(proposal_states_path(route_params))
            expect(flash[:notice]).to be_present
          end

          it "assigns the correct component" do
            post :create, params: valid_params
            expect(ProposalState.last.component).to eq(component)
          end

          it "sets an automatic weight" do
            ProposalState.where(component:).destroy_all
            create(:proposal_state, component:, weight: 5)

            post :create, params: valid_params
            expect(ProposalState.last.weight).to eq(6)
          end

          context "with invalid params" do
            let(:invalid_params) do
              route_params(
                proposal_state: {
                  title: { en: "" }
                }
              )
            end

            it "does not create a proposal state" do
              expect do
                post :create, params: invalid_params
              end.not_to change(ProposalState, :count)
            end

            it "renders new template" do
              post :create, params: invalid_params
              expect(response).to render_template(:new)
            end
          end
        end

        describe "GET #edit" do
          let(:proposal_state) { create(:proposal_state, component:) }

          it "renders successfully" do
            get :edit, params: route_params(id: proposal_state.id)
            expect(response).to be_successful
          end

          it "loads the proposal state" do
            get :edit, params: route_params(id: proposal_state.id)
            expect(assigns(:form).title).to eq(proposal_state.title)
          end
        end

        describe "PATCH #update" do
          let(:proposal_state) { create(:proposal_state, component:) }

          context "when updating a specific proposal state" do
            let(:params) do
              route_params(
                id: proposal_state.id,
                proposal_state: { title: { en: "Updated" } }
              )
            end

            it "updates the proposal state" do
              patch(:update, params:)
              expect(proposal_state.reload.title["en"]).to eq("Updated")
            end

            it "redirects to index" do
              patch(:update, params:)
              expect(response).to redirect_to(proposal_states_path(route_params))
            end

            it "shows success message" do
              patch(:update, params:)
              expect(flash[:notice]).to be_present
            end

            context "with invalid params" do
              let(:invalid_params) do
                route_params(
                  id: proposal_state.id,
                  proposal_state: { title: { en: "" } }
                )
              end

              it "does not update the proposal state" do
                original_title = proposal_state.title
                patch :update, params: invalid_params
                expect(proposal_state.reload.title).to eq(original_title)
              end

              it "renders edit template" do
                patch :update, params: invalid_params
                expect(response).to render_template(:edit)
              end
            end
          end

          context "when reordering proposal states" do
            before do
              ProposalState.where(component:).destroy_all
            end

            let!(:state1) { create(:proposal_state, component:, weight: 1) }
            let!(:state2) { create(:proposal_state, component:, weight: 2) }
            let!(:state3) { create(:proposal_state, component:, weight: 3) }

            let(:reorder_params) do
              route_params(
                id: "refresh_proposal_states",
                manifests: [state3.id, state1.id, state2.id]
              )
            end

            it "reorders proposal states successfully" do
              patch :update, params: reorder_params

              expect(response).to have_http_status(:ok)
              expect(state3.reload.weight).to eq(1)
              expect(state1.reload.weight).to eq(2)
              expect(state2.reload.weight).to eq(3)
            end

            it "maintains the correct order after reordering" do
              patch :update, params: reorder_params

              ordered_states = ProposalState.where(component:).order(:weight)
              expect(ordered_states.pluck(:id)).to eq([state3.id, state1.id, state2.id])
            end

            it "returns unprocessable_entity when manifests are blank" do
              patch :update, params: route_params(id: "refresh_proposal_states", manifests: [])
              expect(response).to have_http_status(:unprocessable_entity)
            end

            it "returns unprocessable_entity when manifests are nil" do
              patch :update, params: route_params(id: "refresh_proposal_states", manifests: nil)
              expect(response).to have_http_status(:unprocessable_entity)
            end

            context "with partial manifest" do
              it "only updates the specified states" do
                partial_params = route_params(
                  id: "refresh_proposal_states",
                  manifests: [state2.id, state1.id]
                )

                patch :update, params: partial_params

                expect(response).to have_http_status(:ok)
                expect(state2.reload.weight).to eq(1)
                expect(state1.reload.weight).to eq(2)
                expect(state3.reload.weight).to eq(3)
              end
            end

            context "with invalid state ids" do
              it "ignores invalid ids and updates valid ones" do
                invalid_params = route_params(
                  id: "refresh_proposal_states",
                  manifests: [state1.id, 99_999, state2.id]
                )

                patch :update, params: invalid_params

                expect(response).to have_http_status(:ok)
                expect(state1.reload.weight).to eq(1)
                expect(state2.reload.weight).to eq(3)
              end
            end
          end
        end

        describe "DELETE #destroy" do
          let!(:proposal_state) { create(:proposal_state, component:) }

          before do
            allow(ProposalState).to receive(:system?).and_return(false)
          end

          it "deletes the proposal state" do
            expect do
              delete :destroy, params: route_params(id: proposal_state.id)
            end.to change(ProposalState, :count).by(-1)
          end

          it "redirects to index" do
            delete :destroy, params: route_params(id: proposal_state.id)
            expect(response).to redirect_to(proposal_states_path(route_params))
          end

          it "shows success message" do
            delete :destroy, params: route_params(id: proposal_state.id)
            expect(flash[:notice]).to be_present
          end
        end

        describe "ordering behavior" do
          before do
            ProposalState.where(component:).destroy_all
          end

          it "orders by weight in proposal_states method" do
            create(:proposal_state, component:, weight: 15)
            create(:proposal_state, component:, weight: 5)
            create(:proposal_state, component:, weight: 10)

            get :index, params: route_params
            weights = controller.send(:proposal_states).map(&:weight)
            expect(weights).to eq([5, 10, 15])
          end

          it "maintains ordering after creating new states" do
            create(:proposal_state, component:, weight: 1)
            create(:proposal_state, component:, weight: 3)
            create(:proposal_state, component:, weight: 2)

            get :index, params: route_params
            weights = controller.send(:proposal_states).map(&:weight)
            expect(weights).to eq([1, 2, 3])
          end
        end

        describe "helper methods" do
          it "exposes proposal_states as helper method" do
            expect(controller.class._helper_methods).to include(:proposal_states)
          end

          it "exposes proposal_state as helper method" do
            expect(controller.class._helper_methods).to include(:proposal_state)
          end
        end
      end
    end
  end
end
