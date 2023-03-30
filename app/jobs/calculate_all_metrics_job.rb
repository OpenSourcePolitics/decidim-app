# frozen_string_literal: true

class CalculateAllMetricsJob < ApplicationJob
  sidekiq_options retry: 1, queue: :metrics

  def perform
    Decidim::Organization.find_each do |organization|
      Decidim.metrics_registry.all.each do |metric_manifest|
        call_metric_job(metric_manifest, organization)
      end
    end
  end

  private

  def call_metric_job(metric_manifest, organization, day = nil)
    Decidim::MetricJob.perform_later(
      metric_manifest.manager_class,
      organization,
      day
    )
  end
end
