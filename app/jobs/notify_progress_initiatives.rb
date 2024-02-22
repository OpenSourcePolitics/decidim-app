# frozen_string_literal: true

class NotifyProgressInitiatives < ApplicationJob
  def perform
    system "rake decidim_initiatives:notify_progress"
  end
end
