# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Content
    describe AttachmentSerializer do
      subject(:serialized) { serializer.serialize }

      let(:serializer) { described_class.new(attachment) }
      let(:proposal) { create(:proposal) }

      # `switch_url_port` reads the port of a running server, which a spec doesn't have.
      before { allow(serializer).to receive(:switch_url_port) { |url| url } }

      context "when the attachment is a photo" do
        let(:attachment) { create(:attachment, :with_image, attached_to: proposal) }

        it "exports the file's content type" do
          expect(serialized[:content_type]).to eq("image/jpeg")
        end
      end

      context "when the attachment is a document" do
        let(:attachment) { create(:attachment, :with_pdf, attached_to: proposal) }

        it "exports the file's content type" do
          expect(serialized[:content_type]).to eq("application/pdf")
        end
      end
    end
  end
end
