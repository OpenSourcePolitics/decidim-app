# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe ProposalsController do
      routes { Decidim::Proposals::Engine.routes }

      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:proposal_params) do
        {
          component_id: component.id
        }
      end
      let(:params) { { proposal: proposal_params } }

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
        stub_const("Decidim::Paginable::OPTIONS", [100])
      end

      describe "GET index" do
        context "when participatory texts are disabled" do
          let(:component) { create(:proposal_component, :with_geocoding_enabled) }

          it "sorts proposals by search defaults" do
            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:index)
            expect(assigns(:proposals).order_values).to eq(["position(decidim_proposals_proposals.id::text in '')"])
          end

          it "sets two different collections" do
            geocoded_proposals = create_list(:proposal, 10, component:, latitude: 1.1, longitude: 2.2)
            non_geocoded_proposals = create_list(:proposal, 2, component:, latitude: nil, longitude: nil)

            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:index)

            expect(assigns(:proposals).count).to eq 12
            expect(assigns(:proposals)).to match_array(geocoded_proposals + non_geocoded_proposals)
          end
        end

        context "when participatory texts are enabled" do
          let(:component) { create(:proposal_component, :with_participatory_texts_enabled) }

          it "sorts proposals by position" do
            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:participatory_text)
            expect(assigns(:proposals).order_values.first.expr.name).to eq("position")
          end

          context "when emendations exist" do
            let!(:amendable) { create(:proposal, component:) }
            let!(:emendation) { create(:proposal, component:) }
            let!(:amendment) { create(:amendment, amendable:, emendation:, state: "accepted") }

            it "does not include emendations" do
              get :index
              expect(response).to have_http_status(:ok)
              emendations = assigns(:proposals).select(&:emendation?)
              expect(emendations).to be_empty
            end
          end
        end
      end
    end
  end
end
