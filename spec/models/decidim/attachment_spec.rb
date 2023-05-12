# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Attachment do
    subject { build(:attachment) }

    let(:organization) { subject.organization }

    it { is_expected.to be_valid }

    context "when it has an image" do
      subject { build(:attachment, :with_image) }

      it "has a thumbnail" do
        expect(subject.thumbnail_url).not_to be_nil
      end

      it "has a big version" do
        expect(subject.big_url).not_to be_nil
      end

      context "when the image is an invariable format" do
        before do
          allow(ActiveStorage).to receive(:variable_content_types).and_return(%w(image/bmp))
        end

        it "has a thumbnail" do
          expect(subject.thumbnail_url).not_to be_nil
        end

        it "has a big version" do
          expect(subject.big_url).not_to be_nil
        end
      end

      describe "photo?" do
        it "returns true" do
          expect(subject.photo?).to be(true)
        end
      end

      describe "document?" do
        it "returns false" do
          expect(subject.document?).to be(false)
        end
      end
    end

    context "when it has a document" do
      subject { build(:attachment, :with_pdf) }

      it "does not have a thumbnail" do
        expect(subject.thumbnail_url).to be_nil
      end

      it "does not have a big version" do
        expect(subject.big_url).to be_nil
      end

      describe "photo?" do
        it "returns false" do
          expect(subject.photo?).to be(false)
        end
      end

      describe "document?" do
        it "returns true" do
          expect(subject.document?).to be(true)
        end
      end
    end
  end
end
