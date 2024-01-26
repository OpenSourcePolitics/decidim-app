# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rake decidim:repair:nickname", type: :task do
  it "uses the appropriate service" do
    allow(Decidim::RepairNicknameService).to receive(:run)

    task.execute

    expect(Decidim::RepairNicknameService).to have_received(:run).once
  end

  describe "logging" do
    let!(:logger) { Logger.new($stdout) }

    before do
      # Stub the logger
      allow(logger).to receive(:info)
      allow(Logger).to receive(:new).and_return(logger)

      allow(Decidim::RepairNicknameService).to receive(:run).and_return updated_user_ids
    end

    context "when no nickname was repaired" do
      let(:updated_user_ids) { [] }

      it "logs a message" do
        task.execute

        expect(logger).to have_received(:info).with("No users updated")
      end
    end

    context "when some nicknames were repaired" do
      let(:updated_user_ids) { [1, 2, 3] }

      it "logs a message" do
        task.execute

        expect(logger).to have_received(:info).with("Updated users ID : 1, 2, 3")
      end
    end
  end
end
