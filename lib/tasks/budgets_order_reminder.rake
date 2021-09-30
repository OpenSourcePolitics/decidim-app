# frozen_string_literal: true

namespace :budgets do
  desc "Deploy a test version on heroku"
  task remind_pending_order: :environment do
    OrdersReminderJob.perform_later
  end
end
