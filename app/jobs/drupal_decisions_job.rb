# frozen_string_literal: true

class DrupalDecisionsJob < ApplicationJob
  queue_as :exports

  def perform(*args)
    Decidim::DrupalDecisionsImporterService.run(*args)
  end
end
