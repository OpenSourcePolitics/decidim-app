# frozen_string_literal: true

class DrupalCleanSpamUsersJob < ApplicationJob
  queue_as :exports

  def perform(*args)
    Decidim::DrupalSpamUsersCleanerService.run(*args)
  end
end
