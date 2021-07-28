# frozen_string_literal: true

require "rake"

class OrdersReminderJob < ApplicationJob
  queue_as :scheduled

  def perform
    system "rake decidim:budgets:reminder"
  end
end
