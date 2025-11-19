# frozen_string_literal: true

require "spec_helper"

describe Decidim::FindAndUpdateDescendantsJob do
  subject { described_class }

  let!(:participatory_process) { create(:participatory_process) }
  let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
  let!(:proposal) { create(:proposal, :official, component: proposal_component) }

  describe "queue" do
    it "is queued to events" do
      expect(subject.queue_name).to eq "default"
    end
  end

  describe "#perform" do
    it "enqueues a job with perform_later" do
      expect {
        Decidim::FindAndUpdateDescendantsJob.perform_later(participatory_process)
      }.to have_enqueued_job(Decidim::FindAndUpdateDescendantsJob).with(participatory_process)
    end

    it "calls process_element_and_descendants private method" do
      job = described_class.new
      allow(job).to receive(:process_element_and_descendants)

      job.perform(participatory_process)
      expect(job).to have_received(:process_element_and_descendants).with(participatory_process)
    end
  end
end
