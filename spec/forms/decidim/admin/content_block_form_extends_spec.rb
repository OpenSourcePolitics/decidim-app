# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Admin
    describe ContentBlockForm do
      subject do
        described_class.from_params(attributes).with_context(
          current_organization: organization
        )
      end

      let(:organization) { create(:organization) }
      let(:assembly) { create(:assembly, organization:) }
      let(:content_block) do
        create(:content_block,
               manifest_name: "hero",
               scope_name: "assembly_homepage",
               scoped_resource_id: assembly.id,
               organization:)
      end

      let(:attributes) do
        {
          "id" => content_block.id,
          "settings" => { "button_text_fr" => "Test" },
          "images" => { "background_image" => "some-signed-id" }
        }
      end

      describe "#images" do
        it "returns an images_container, never the raw submitted hash" do
          expect(subject.images).not_to be_a(Hash)
        end
      end

      describe "#image_params" do
        it "returns the raw submitted params for the command to consume" do
          expect(subject.image_params).to be_a(Hash)
          expect(subject.image_params[:background_image]).to eq("some-signed-id")
        end
      end
    end
  end
end
