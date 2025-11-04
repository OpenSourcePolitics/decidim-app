# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe ProposalState do
      subject { proposal_state }

      let(:component) { build(:proposal_component) }
      let(:organization) { component.participatory_space.organization }
      let(:proposal_state) { create(:proposal_state, component:) }

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      describe "system" do
        let(:proposal_state) { create(:proposal_state, :accepted, component:) }

        it "prevents deletion" do
          expect { proposal_state.destroy }.not_to change(Decidim::Proposals::ProposalState, :count)
        end
      end

      describe "weight management" do
        before do
          ProposalState.where(component:).destroy_all
        end

        context "when creating a new proposal state" do
          it "sets a default weight" do
            state = build(:proposal_state, component:, weight: nil)
            expect(state.weight).to be_nil
            state.save!
            expect(state.weight).to eq(1)
          end

          it "increments weight based on existing states" do
            create(:proposal_state, component:, weight: 5)
            create(:proposal_state, component:, weight: 10)

            new_state = create(:proposal_state, component:, weight: nil)
            expect(new_state.weight).to eq(11)
          end

          it "does not override manually set weight" do
            state = create(:proposal_state, component:, weight: 42)
            expect(state.weight).to eq(42)
          end

          it "scopes weight calculation to component" do
            other_component = create(:proposal_component)
            ProposalState.where(component: other_component).destroy_all
            create(:proposal_state, component: other_component, weight: 100)

            new_state = create(:proposal_state, component:, weight: nil)
            expect(new_state.weight).to eq(1)
          end

          it "handles the first state in a component" do
            new_component = create(:proposal_component)
            ProposalState.where(component: new_component).destroy_all

            first_state = create(:proposal_state, component: new_component, weight: nil)
            expect(first_state.weight).to eq(1)
          end
        end

        context "when updating a proposal state" do
          it "does not modify weight on update" do
            state = create(:proposal_state, component:, weight: 5)
            original_weight = state.weight

            state.update!(title: { en: "Updated title" })
            expect(state.weight).to eq(original_weight)
          end
        end
      end

      describe ".ordered_by_weight" do
        before do
          ProposalState.where(component:).destroy_all
        end

        let!(:state1) { create(:proposal_state, component:, weight: 10) }
        let!(:state2) { create(:proposal_state, component:, weight: 5) }
        let!(:state3) { create(:proposal_state, component:, weight: 15) }

        it "returns states ordered by weight ascending" do
          ordered_states = described_class.where(component:).ordered_by_weight
          expect(ordered_states.pluck(:weight)).to eq([5, 10, 15])
          expect(ordered_states.map(&:id)).to eq([state2.id, state1.id, state3.id])
        end
      end
    end
  end
end
