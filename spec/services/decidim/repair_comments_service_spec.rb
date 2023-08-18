# frozen_string_literal: true

require "spec_helper"

describe Decidim::RepairCommentsService do
  subject { described_class.new }

  let!(:comments) { create_list(:comment, 10) }

  describe "#execute" do
    it "returns empty array" do
      expect(subject.execute).to be_empty
    end

    it "does not change valid comments" do
      expect { subject.execute }.not_to(change { comments.map(&:body) })
    end

    context "when invalid bodys" do
      let(:invalid) { build :comment }

      before do
        invalid.body = { "en" => { "en" => "foobar" } }
        invalid.save!(validate: false)
      end

      it "returns array of invalid comments IDs" do
        expect(subject.execute).to eq([invalid.id])
        invalid.reload.body.delete("machine_translations")
        expect(invalid.body).to eq({ "en" => "foobar" })
      end
    end
  end

  describe "#ok?" do
    it "returns true" do
      expect(subject).to be_ok
    end
  end

  describe "#invalid_comments" do
    let(:invalid) { build :comment }

    before do
      invalid.body = { "en" => { "en" => "foobar" } }
      invalid.save!(validate: false)
    end

    it "returns array of invalid comments" do
      expect(subject.invalid_comments).to eq([[invalid, { "en" => "foobar" }]])
    end
  end
end
