# frozen_string_literal: true

class DrupalJob < ApplicationJob
  queue_as :exports

  def perform(*args)
    Decidim::DrupalImporterService.run(*args)
  end
end