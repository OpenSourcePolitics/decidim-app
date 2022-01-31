# frozen_string_literal: true

class OrdersReminderJob < ApplicationJob
  queue_as :scheduled

  def perform
    return if pending_orders.empty?

    pending_orders.each do |pending_order|
      send_notification(pending_order.user, pending_order.budget)
    end
  end

  private

  def pending_orders
    @pending_orders ||= Decidim::Budgets::Order.where(checked_out_at: nil)
                                               .reject { |order| order.component.published_at.nil? }
                                               .reject { |order| order.component.participatory_space.published_at.nil? }
  end

  def send_notification(user, budget)
    Decidim::EventsManager.publish(
      event: "decidim.events.budgets.pending_order",
      event_class: Decidim::Budgets::PendingOrderEvent,
      resource: budget,
      followers: [user]
    )
  end
end
