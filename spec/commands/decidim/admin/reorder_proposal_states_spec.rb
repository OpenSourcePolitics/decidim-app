# frozen_string_literal: true

require "spec_helper"

module Admin
  describe ReorderProposalStates do
    subject { described_class.new(component, ids) }

    let(:organization) { create(:organization) }
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:component) { create(:proposal_component, participatory_space: participatory_process) }

    before do
      Decidim::Proposals::ProposalState.where(component:).destroy_all
    end

    # rubocop:disable RSpec/ScatteredLet
    let!(:state1) { create(:proposal_state, component:, weight: 1) }
    let!(:state2) { create(:proposal_state, component:, weight: 2) }
    let!(:state3) { create(:proposal_state, component:, weight: 3) }
    # rubocop:enable RSpec/ScatteredLet

    describe "#call" do
      context "when ids are valid" do
        let(:ids) { [state3.id, state1.id, state2.id] }

        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end

        it "reorders the proposal states" do
          subject.call

          expect(state3.reload.weight).to eq(1)
          expect(state1.reload.weight).to eq(2)
          expect(state2.reload.weight).to eq(3)
        end

        it "maintains the new order in database" do
          subject.call

          ordered_states = Decidim::Proposals::ProposalState
                           .where(component:)
                           .order(:weight)
                           .pluck(:id)

          expect(ordered_states).to eq([state3.id, state1.id, state2.id])
        end
      end

      context "when reordering in reverse order" do
        let(:ids) { [state3.id, state2.id, state1.id] }

        it "applies the correct weights" do
          subject.call

          expect(state3.reload.weight).to eq(1)
          expect(state2.reload.weight).to eq(2)
          expect(state1.reload.weight).to eq(3)
        end
      end

      context "when ids are blank" do
        let(:ids) { [] }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end

        it "does not modify any weights" do
          expect do
            subject.call
          end.not_to(change { state1.reload.weight })
        end
      end

      context "when ids are nil" do
        let(:ids) { nil }

        it "broadcasts invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end

        it "does not modify any weights" do
          expect do
            subject.call
          end.not_to(change { state1.reload.weight })
        end
      end

      context "with partial list of ids" do
        let(:ids) { [state2.id, state1.id] }

        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end

        it "only updates specified states" do
          subject.call

          expect(state2.reload.weight).to eq(1)
          expect(state1.reload.weight).to eq(2)
          expect(state3.reload.weight).to eq(3)
        end
      end

      context "with invalid ids mixed with valid ones" do
        let(:ids) { [state1.id, 99_999, state2.id] }

        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end

        it "updates valid states and skips invalid ones" do
          subject.call

          expect(state1.reload.weight).to eq(1)
          expect(state2.reload.weight).to eq(3)
        end
      end

      context "with states from different components" do
        let(:other_component) { create(:proposal_component, participatory_space: participatory_process) }
        let!(:other_state) { create(:proposal_state, component: other_component, weight: 1) }
        let(:ids) { [other_state.id, state1.id, state2.id] }

        it "only reorders states from the current component" do
          subject.call

          expect(state1.reload.weight).to eq(2)
          expect(state2.reload.weight).to eq(3)
          expect(other_state.reload.weight).to eq(1)
        end
      end

      context "with duplicate ids" do
        let(:ids) { [state1.id, state2.id, state1.id] }

        it "broadcasts ok" do
          expect { subject.call }.to broadcast(:ok)
        end

        it "handles duplicates without errors" do
          expect { subject.call }.not_to raise_error
        end
      end

      context "when an error occurs during update" do
        let(:ids) { [state1.id, state2.id, state3.id] }

        it "rolls back the transaction" do
          @original_weights = {
            state1: state1.weight,
            state2: state2.weight,
            state3: state3.weight
          }

          allow(Decidim::Proposals::ProposalState).to receive(:where).and_call_original
          allow(Decidim::Proposals::ProposalState).to receive(:where)
            .with(component:, id: ids)
            .and_wrap_original do |method, *args|
            relation = method.call(*args)
            allow(relation).to receive(:each).and_raise(ActiveRecord::RecordInvalid.new(state1))
            relation
          end

          expect { subject.call }.to raise_error(ActiveRecord::RecordInvalid)

          expect(state1.reload.weight).to eq(@original_weights[:state1])
          expect(state2.reload.weight).to eq(@original_weights[:state2])
          expect(state3.reload.weight).to eq(@original_weights[:state3])
        end
      end
    end

    describe "#collection" do
      let(:ids) { [state1.id, state2.id] }

      it "returns states matching the ids and component" do
        collection = subject.collection
        expect(collection.map(&:id)).to contain_exactly(state1.id, state2.id)
      end

      it "only includes states from the current component" do
        other_component = create(:proposal_component, participatory_space: participatory_process)
        other_state = create(:proposal_state, component: other_component)

        subject_with_other = described_class.new(component, [state1.id, other_state.id])
        collection = subject_with_other.collection

        expect(collection.map(&:id)).to eq([state1.id])
      end

      it "memoizes the collection" do
        expect(Decidim::Proposals::ProposalState).to receive(:where).once.and_call_original
        subject.collection
        subject.collection
      end
    end

    describe "weight calculation" do
      let(:ids) { [state3.id, state1.id, state2.id] }

      it "assigns weights based on position in array starting at 1" do
        subject.call

        expect(state3.reload.weight).to eq(1)
        expect(state1.reload.weight).to eq(2)
        expect(state2.reload.weight).to eq(3)
      end

      it "creates sequential weights without gaps" do
        subject.call

        weights = Decidim::Proposals::ProposalState
                  .where(component:)
                  .order(:weight)
                  .pluck(:weight)

        expect(weights).to eq([1, 2, 3])
      end
    end

    describe "with string ids" do
      let(:ids) { [state1.id.to_s, state2.id.to_s] }

      it "handles string ids correctly" do
        subject.call

        expect(state1.reload.weight).to eq(1)
        expect(state2.reload.weight).to eq(2)
      end
    end

    describe "transaction behavior" do
      let(:ids) { [state1.id, state2.id, state3.id] }

      it "executes within a transaction" do
        expect(subject).to receive(:transaction).and_call_original
        subject.call
      end
    end

    describe "edge cases" do
      context "with single state" do
        let(:ids) { [state1.id] }

        it "assigns weight 1" do
          subject.call
          expect(state1.reload.weight).to eq(1)
        end
      end

      context "with all states in original order" do
        let(:ids) { [state1.id, state2.id, state3.id] }

        it "maintains sequential weights" do
          subject.call

          expect(state1.reload.weight).to eq(1)
          expect(state2.reload.weight).to eq(2)
          expect(state3.reload.weight).to eq(3)
        end
      end

      context "when component has no states" do
        let(:empty_component) { create(:proposal_component, participatory_space: participatory_process) }
        let(:ids) { [99_999] }

        subject { described_class.new(empty_component, ids) }

        it "broadcasts ok without errors" do
          expect { subject.call }.to broadcast(:ok)
        end
      end
    end
  end
end
