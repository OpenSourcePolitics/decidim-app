# frozen_string_literal: true

class AuthorizationDataToUserDataJob < ApplicationJob
  queue_as :exports

  def perform(*args)
    Decidim::AuthorizationDataToUserDataService.run(*args)
  end
end
