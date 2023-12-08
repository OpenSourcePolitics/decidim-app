# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rake decidim:repair:comments", type: :task do
  it "uses the appropriate service" do
    allow(Decidim::RepairCommentsService).to receive(:run)

    task.execute

    expect(Decidim::RepairCommentsService).to have_received(:run).once
  end

  describe "logging" do
    let!(:logger) { Logger.new($stdout) }

    before do
      # Stub the logger
      allow(logger).to receive(:info)
      allow(Logger).to receive(:new).and_return(logger)

      allow(Decidim::RepairCommentsService).to receive(:run).and_return updated_comments_ids
    end

    context "when no nickname was repaired" do
      let(:updated_comments_ids) { [] }

      it "logs a message" do
        task.execute

        expect(logger).to have_received(:info).with("No comments updated")
      end
    end

    context "when some nicknames were repaired" do
      let(:updated_comments_ids) { [1, 2, 3] }

      it "logs a message" do
        task.execute

        expect(logger).to have_received(:info).with("Updated comments ID : 1, 2, 3")
      end
    end
  end
end
