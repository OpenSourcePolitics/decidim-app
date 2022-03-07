# frozen_string_literal: true

require "spec_helper"

describe OrdersReminderJob do
  subject { described_class }

  let(:task) { Rake::Task["budgets:remind_pending_order"] }
  let(:organization) { create(:organization) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:budgets_component, participatory_space: participatory_space) }
  let!(:budget) { create(:budget, component: component) }
  let!(:order) { create(:order, budget: budget) }
  let(:user) { order.user }

  it "doesn't raise an error" do
    expect { subject.perform_now }.not_to raise_error
  end

  it "sends a notification per user" do
    expect(Decidim::EventsManager)
      .to receive(:publish)
      .with(
        event: "decidim.events.budgets.pending_order",
        event_class: Decidim::Budgets::PendingOrderEvent,
        resource: budget,
        followers: [user]
      )

    subject.perform_now
  end

  describe "#pending_orders" do
    context "when there is no pending orders" do
      let!(:order) { create(:order, budget: budget) }

      it "returns nothing" do
        # rubocop:disable Rails/SkipsModelValidations
        order.update_column(:checked_out_at, Time.current)
        # rubocop:enable Rails/SkipsModelValidations

        expect(subject.new.send(:pending_orders)).to eq([])
      end
    end

    it "returns pending orders" do
      expect(subject.new.send(:pending_orders)).to eq([order])
    end

    context "when component is unpublished" do
      let(:component) { create(:budgets_component) }

      it "returns nothing" do
        component.update!(published_at: nil)

        expect(subject.new.send(:pending_orders)).to eq([])
      end
    end

    context "when participatory space is unpublished" do
      let(:participatory_space) { create(:participatory_process, :with_steps, :unpublished, organization: organization) }

      it "returns nothing" do
        expect(subject.new.send(:pending_orders)).to eq([])
      end
    end
  end
end
