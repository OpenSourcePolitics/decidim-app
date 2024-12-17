# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe PapertrailVersionsJob do
    let!(:valid_versions) { create_list(:paper_trail_version, 10, item_id: 10) }
    let!(:invalid_versions) { create_list(:paper_trail_version, 10, item_id: 10, item_type: item_type, created_at: created_at) }
    let(:item_type) { "Decidim::UserBaseEntity" }
    let(:created_at) { 8.months.ago }

    it "removes invalid versions" do
      expect do
        described_class.perform_now
      end.to change(PaperTrail::Version, :count).from(20).to(10)
    end

    it "allows to set the expiration limit" do
      expect do
        described_class.perform_now(11.months.ago)
      end.not_to change(PaperTrail::Version, :count)
    end

    context "when no versions older than 6 months" do
      let(:created_at) { 1.day.ago }

      it "do not remove any papertrail version" do
        expect do
          described_class.perform_now
        end.not_to change(PaperTrail::Version, :count)
      end
    end
  end
end
