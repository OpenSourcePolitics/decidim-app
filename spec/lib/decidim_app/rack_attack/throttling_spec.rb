# frozen_string_literal: true

require "spec_helper"

describe DecidimApp::RackAttack::Throttling do
  describe "#name?" do
    it "returns true" do
      expect(described_class.name).to eq("req/ip")
    end
  end

  describe "#max_requests" do
    it "returns 100 by default" do
      expect(described_class.max_requests).to eq(100)
    end
  end

  describe "#period" do
    it "returns 60 by default" do
      expect(described_class.period).to eq(60)
    end
  end

  describe "#time_limit_for" do
    let(:match_data_h) { nil }

    it "returns 60 by default" do
      expect(described_class.time_limit_for(match_data_h)).to eq(60)
    end

    context "with defined match_data_h" do
      let(:match_data_h) do
        {
          epoch_time: Date.new(2023,5,22).to_time.to_i,
          period: 30
        }
      end

      it "returns new limit" do
        expect(described_class.time_limit_for(match_data_h)).to eq(30)
      end
    end
  end
end
