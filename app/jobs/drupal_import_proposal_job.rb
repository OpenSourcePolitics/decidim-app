# frozen_string_literal: true

class DrupalImportProposalJob < ApplicationJob
  queue_as :exports

  def perform(*args)
    Decidim::DrupalProposalImporterService.run(*args)
  end
end
