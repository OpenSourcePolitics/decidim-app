# frozen_string_literal: true

class DrupalPpsCheckJob < ApplicationJob
  queue_as :exports

  def perform(*args)
    Decidim::DrupalPpsCheckService.run(*args)
  end
end
