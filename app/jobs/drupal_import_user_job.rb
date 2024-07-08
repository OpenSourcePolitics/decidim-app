# frozen_string_literal: true

class DrupalImportUserJob < ApplicationJob
  queue_as :exports

  def perform(*args)
    Decidim::DrupalUserImporterService.run(*args)
  end
end
