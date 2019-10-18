# frozen_string_literal: true
require "rake"

class CalculateAllMetricsJob < ApplicationJob

  def perform
    system "decidim:metrics:all"
  end
end
