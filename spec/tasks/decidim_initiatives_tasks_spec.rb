# frozen_string_literal: true

require "spec_helper"

describe "decidim_initiatives:check_published", type: :task do
  let(:organization) { create(:organization) }
  let(:initiative_type) { create(:initiatives_type, organization:) }
  let(:initiative_type_scope) { create(:initiatives_type_scope, type: initiative_type) }

  context "when the signing period has ended" do
    context "when the initiative has NOT reached the signature threshold" do
      let!(:initiative) do
        create(
          :initiative,
          :published,
          :rejectable,
          organization:,
          scoped_type: initiative_type_scope,
          signature_end_date: 1.day.ago
        )
      end

      it "moves the initiative to rejected state" do
        expect { task.execute }.to change { initiative.reload.state }.from("published").to("rejected")
      end
    end

    context "when the initiative HAS reached the signature threshold" do
      let!(:initiative) do
        create(
          :initiative,
          :published,
          :acceptable,
          organization:,
          scoped_type: initiative_type_scope,
          signature_end_date: 1.day.ago
        )
      end

      it "moves the initiative to accepted state" do
        expect { task.execute }.to change { initiative.reload.state }.from("published").to("accepted")
      end
    end
  end

  context "when the signing period is still active" do
    let!(:initiative) do
      create(
        :initiative,
        :published,
        :rejectable,
        organization:,
        scoped_type: initiative_type_scope,
        signature_end_date: 1.day.from_now
      )
    end

    it "does not change the initiative state" do
      expect { task.execute }.not_to(change { initiative.reload.state })
    end
  end

  context "when the initiative is not in published state" do
    let!(:initiative) do
      create(
        :initiative,
        :created,
        organization:,
        scoped_type: initiative_type_scope,
        signature_end_date: 1.day.ago
      )
    end

    it "does not change the initiative state" do
      expect { task.execute }.not_to(change { initiative.reload.state })
    end
  end
end
