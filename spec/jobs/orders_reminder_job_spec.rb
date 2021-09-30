# frozen_string_literal: true

require "spec_helper"

describe OrdersReminderJob do
  subject { described_class }

  let(:task) { Rake::Task["budgets:remind_pending_order"] }
  let!(:budget) { create(:budget) }
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
        order.update_column(:checked_out_at, Time.current)

        expect(subject.new.send(:pending_orders)).to eq([])
      end
    end

    it "returns pending orders" do
      expect(subject.new.send(:pending_orders)).to eq([order])
    end
  end
end