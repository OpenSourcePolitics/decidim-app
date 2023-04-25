# frozen_string_literal: true

require "spec_helper"

describe Decidim::RepairNicknameService do
  subject { described_class.new }

  let!(:users) { create_list(:user, 10) }

  describe "#run" do
    subject { described_class.run }

    it "returns empty array" do
      expect(subject).to be_empty
    end

    context "when invalid nicknames" do
      let(:invalid) { build :user }

      before do
        invalid.nickname = "Décidim"
        invalid.save!(validate: false)
      end

      it "returns array of invalid user IDs" do
        expect(subject).to eq([invalid.id])
      end
    end
  end

  describe "#ok?" do
    it "returns true" do
      expect(subject).to be_ok
    end
  end
end
