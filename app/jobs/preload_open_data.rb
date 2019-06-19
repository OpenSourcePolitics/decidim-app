# frozen_string_literal: true

class PreloadOpenDataJob < ApplicationJob

  def perform
    application_name = Rails.application.class.parent_name
    application = Object.const_get(application_name)
    application::Application.load_tasks
    Rake::Task["decidim:open_data:export"].invoke
  end
end
