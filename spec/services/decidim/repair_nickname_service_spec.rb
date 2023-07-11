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
      expect(subject.invalid_users).to eq([invalid])
    end
  end
end
