# frozen_string_literal: true

require "spec_helper"

describe DecidimApp::RackAttack do
  describe "#rack_enabled?" do
    it "returns false" do
      expect(described_class).not_to be_rack_enabled # env var nil
    end

    context "when ENV variable is set to '1'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :enabled).and_return("1")
      end

      it "returns true" do
        expect(described_class).to be_rack_enabled
      end
    end

    context "when ENV variable is set to '0'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :enabled).and_return("0")
      end

      it "returns false" do
        expect(described_class).not_to be_rack_enabled
      end
    end

    context "when rails env is production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "returns true" do
        expect(described_class).to be_rack_enabled
      end

      context "when ENV variable is set to '1'" do
        before do
          allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :enabled).and_return("1")
        end

        it "returns true" do
          expect(described_class).to be_rack_enabled
        end
      end

      context "when ENV variable is set to '0'" do
        before do
          allow(Rails.application.secrets).to receive(:dig).with(:decidim, :rack_attack, :enabled).and_return("0")
        end

        it "returns false" do
          expect(described_class).not_to be_rack_enabled
        end
      end
    end
  end
end
