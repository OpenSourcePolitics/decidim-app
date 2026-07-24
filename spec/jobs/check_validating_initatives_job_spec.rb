# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe CheckValidatingInitiatives do
      subject { described_class }

      describe "queue" do
        it "is queued to initiatives" do
          expect(subject.queue_name).to eq "initiatives"
        end
      end

      describe "#perform" do
        it "enqueues a job with perform_later" do
          expect do
            described_class.perform_later
          end.to have_enqueued_job(described_class)
        end

        it "runs the check_validating rake task" do
          job = described_class.new
          allow(job).to receive(:system)

          job.perform

          expect(job).to have_received(:system).with("rake decidim_initiatives:check_validating")
        end
      end
    end
  end
end
