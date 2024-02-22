# frozen_string_literal: true

class CheckPublishedInitiatives < ApplicationJob
  def perform
    system "rake decidim_initiatives:check_published"
  end
end
