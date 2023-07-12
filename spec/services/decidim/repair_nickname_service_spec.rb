# frozen_string_literal: true

require "spec_helper"

describe Decidim::RepairNicknameService do
  subject { described_class.new }

  let!(:users) { create_list(:user, 10) }

  describe "#execute" do
    it "returns empty array" do
      expect(subject.execute).to be_empty
    end

    context "when invalid nicknames" do
      let(:invalid) { build :user }

      before do
        invalid.nickname = "Décidim"
        invalid.save!(validate: false)
      end

      it "returns array of invalid user IDs" do
        expect(subject.execute).to eq([invalid.id])
        expect(invalid.reload.nickname).to eq("Decidim")
      end

      context "when the fixed item would match an existing nickname" do
        before do
          create(:user, nickname: "Decidim")
        end

        it "returns array of invalid user IDs" do
          expect(subject.execute).to eq([invalid.id])
          expect(invalid.reload.nickname).to eq("Decidim#{invalid.id}")
        end
      end
    end
  end

  describe "#ok?" do
    it "returns true" do
      expect(subject).to be_ok
    end
  end

  describe "#invalid_users" do
    let(:invalid) { build :user }

    before do
      invalid.nickname = "Décidim"
      invalid.save!(validate: false)
    end

    it "returns array of invalid users" do
      expect(subject.invalid_users).to eq([[invalid, "Decidim"]])
    end
  end
end
