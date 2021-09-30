# frozen_string_literal: true

namespace :budgets do
  desc "Remind users to checkout their vote"
  task remind_pending_order: :environment do
    OrdersReminderJob.perform_now
  end
end
