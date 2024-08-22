# frozen_string_literal: true

class DrupalImportMeetingJob < ApplicationJob
  queue_as :exports

  def perform(*args)
    Decidim::DrupalMeetingsImporterService.run(*args)
  end
end
