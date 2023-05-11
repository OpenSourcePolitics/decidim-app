# frozen_string_literal: true

require "spec_helper"

describe CalculateAllMetricsJob, type: :job do
  let(:organization) { create(:organization) }
  let(:metric_manifest) { Decidim::MetricManifest.new(metric_name: "metric") }

  describe "#perform" do
    before do
      allow(Decidim::Organization).to receive(:find_each).and_yield(organization)
      allow(Decidim.metrics_registry).to receive(:all).and_return([metric_manifest])
    end

    it "calls MetricJob for each organization and metric_manifest" do
      expect(Decidim::MetricJob).to receive(:perform_later).with(metric_manifest.manager_class, organization, nil)
      subject.perform
    end
  end

  describe "#call_metric_job" do
    it "enqueues the MetricJob with the correct arguments" do
      expect(Decidim::MetricJob).to receive(:perform_later).with(metric_manifest.manager_class, organization, nil)

      subject.send(:call_metric_job, metric_manifest, organization)
    end
  end
end
