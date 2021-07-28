# frozen_string_literal: true

require "rake"

class CalculateAllMetricsJob < ApplicationJob
  queue_as :scheduled

  def perform
    system "rake decidim:metrics:all"
  end
end
