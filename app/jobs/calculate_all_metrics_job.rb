# frozen_string_literal: true

require "rake"

class CalculateAllMetricsJob < ApplicationJob
  queue_as :metrics

  def perform
    Rails.application.load_tasks
    task.reenable
    task.invoke
  end

  def task
    Rake::Task["decidim:metrics:all"]
  end
end
