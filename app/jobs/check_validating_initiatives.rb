# frozen_string_literal: true

class CheckValidatingInitiatives < ApplicationJob
  def perform
    system "rake decidim_initiatives:check_validating"
  end
end
