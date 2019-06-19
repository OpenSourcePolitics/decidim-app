# frozen_string_literal: true

class CalculateAllMetricsJob < ApplicationJob

  def perform
    application_name = Rails.application.class.parent_name
    application = Object.const_get(application_name)
    application::Application.load_tasks
    Rake::Task["decidim:metrics:all"].invoke
  end
end
