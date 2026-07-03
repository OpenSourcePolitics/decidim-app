# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe ContentBlockAttachment do
    let(:organization) { create(:organization) }
    let(:assembly) { create(:assembly, organization:) }
    let(:content_block) do
      create(:content_block,
             manifest_name: "hero",
             scope_name: "assembly_homepage",
             scoped_resource_id: assembly.id,
             organization:)
    end

    describe "#uploader" do
      context "when the attachment is persisted with a name matching the manifest" do
        subject { content_block.attachments.find_or_initialize_by(name: "background_image") }

        it "returns the configured uploader" do
          expect(subject.uploader).to eq(Decidim::BackgroundImageUploader)
        end
      end

      context "when the attachment is built without a name" do
        subject { content_block.attachments.build }

        it "does not return nil" do
          expect(subject.uploader).not_to be_nil
        end
      end
    end
  end
end
