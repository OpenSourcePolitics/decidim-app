# frozen_string_literal: true

require "spec_helper"

describe DecidimApp::DecidimInitiatives do
  subject { described_class }

  describe "#creation_enabled?" do
    it "returns true" do
      expect(subject).to be_creation_enabled
    end

    context "when 'auto'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :creation_enabled).and_return("auto")
      end

      it "returns true" do
        expect(subject).to be_creation_enabled
      end
    end

    context "when empty" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :creation_enabled).and_return("")
      end

      it "returns false" do
        expect(subject).not_to be_creation_enabled
      end
    end
  end

  describe "#similarity_threshold" do
    context "when rails secret '75.0'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :similarity_threshold).and_return(75.0)
      end

      it "returns 75.0" do
        expect(subject.similarity_threshold).to eq(75.0)
      end
    end
  end

  describe "#similarity_limit" do
    context "when rails secret '50'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :similarity_limit).and_return(50)
      end

      it "returns 5" do
        expect(subject.similarity_limit).to eq(50)
      end
    end

    context "when empty returns default" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :similarity_limit).and_return("")
      end

      it "returns 5" do
        expect(subject.similarity_limit).to eq(5)
      end
    end
  end

  describe "#minimum_committee_members" do
    context "when rails secret '365'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :minimum_committee_members).and_return(365)
      end

      it "returns 365" do
        expect(subject.minimum_committee_members).to eq(365)
      end
    end

    context "when empty returns default" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :minimum_committee_members).and_return("")
      end

      it "returns 2" do
        expect(subject.minimum_committee_members).to eq(2)
      end
    end
  end

  describe "#default_signature_time_period_length" do
    context "when rails secret '60'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :default_signature_time_period_length).and_return(60)
      end

      it "returns 60" do
        expect(subject.default_signature_time_period_length).to eq(60)
      end
    end

    context "when empty returns default" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :default_signature_time_period_length).and_return("")
      end

      it "returns 120" do
        expect(subject.default_signature_time_period_length).to eq(120)
      end
    end
  end

  describe "#first_notification_percentage" do
    context "when rails secret '25'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :first_notification_percentage).and_return(25)
      end

      it "returns 25" do
        expect(subject.first_notification_percentage).to eq(25)
      end
    end

    context "when empty returns default" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :first_notification_percentage).and_return("")
      end

      it "returns 33" do
        expect(subject.first_notification_percentage).to eq(33)
      end
    end
  end

  describe "#second_notification_percentage" do
    context "when rails secret '25'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :second_notification_percentage).and_return(25)
      end

      it "returns 25" do
        expect(subject.second_notification_percentage).to eq(25)
      end
    end

    context "when empty returns default" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :second_notification_percentage).and_return("")
      end

      it "returns 66" do
        expect(subject.second_notification_percentage).to eq(66)
      end
    end
  end

  describe "#stats_cache_expiration_time" do
    context "when rails secret '25'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :stats_cache_expiration_time).and_return(25)
      end

      it "returns 25 minutes" do
        expect(subject.stats_cache_expiration_time).to eq(25.minutes)
      end
    end

    context "when empty returns default" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :stats_cache_expiration_time).and_return(5)
      end

      it "returns 5 minutes" do
        expect(subject.stats_cache_expiration_time).to eq(5.minutes)
      end
    end
  end

  describe "#max_time_in_validating_state" do
    context "when rails secret '25'" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :max_time_in_validating_state).and_return(25)
      end

      it "returns 25 days" do
        expect(subject.max_time_in_validating_state).to eq(25.days)
      end
    end

    context "when empty returns default" do
      before do
        allow(Rails.application.secrets).to receive(:dig).with(:decidim, :initiatives, :max_time_in_validating_state).and_return(60)
      end

      it "returns 60 days" do
        expect(subject.max_time_in_validating_state).to eq(60.days)
      end
    end
  end
end
