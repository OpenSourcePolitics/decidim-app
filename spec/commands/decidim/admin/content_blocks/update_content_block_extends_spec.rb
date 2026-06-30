# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Admin
    module ContentBlocks
      describe UpdateContentBlock do
        let(:organization) { create(:organization) }
        let(:assembly) { create(:assembly, organization:) }
        let(:scope) { assembly }
        let(:content_block) do
          create(:content_block,
                 manifest_name: "hero",
                 scope_name: "assembly_homepage",
                 scoped_resource_id: assembly.id,
                 organization:)
        end

        let(:form) do
          Decidim::Admin::ContentBlockForm.from_params(
            "id" => content_block.id,
            "settings" => { "button_text_fr" => "Test" },
            "images" => {}
          ).with_context(current_organization: organization)
        end

        context "when the form has no image params" do
          it "does not raise and broadcasts :ok" do
            result = nil

            expect do
              described_class.call(form, content_block, scope) do
                on(:ok) { result = :ok }
                on(:invalid) { result = :invalid }
              end
            end.not_to raise_error

            expect(result).to eq(:ok)
          end
        end
      end
    end
  end
end
