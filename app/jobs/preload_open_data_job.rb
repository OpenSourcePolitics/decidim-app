# frozen_string_literal: true

require "rake"

class PreloadOpenDataJob < ApplicationJob
  queue_as :scheduled

  def perform
    system "rake decidim:open_data:export"
  end
end
