# frozen_string_literal: true
require "rake"

class PreloadOpenDataJob < ApplicationJob

  def perform
    system "rake decidim:open_data:export"
  end
end
