# frozen_string_literal: true

require "spec_helper"
require "decidim/admin/test/forms/attachment_form_examples"

module Decidim
  module Admin
    describe Decidim::Admin::AttachmentForm do
      context "when attaching a file" do
        include_examples "attachment form" do
          let(:attached_to) do
            create(:participatory_process, organization:)
          end
        end

        context "when the file is persisted and the link is absent" do
          let(:link) { nil }
          let(:file) { nil }
          let(:attributes) do
            { "id" => "1",
              "attachment" => {
                "title_en" => title[:en],
                "title_es" => title[:es],
                "title_ca" => title[:ca],
                "description_en" => description[:en],
                "description_es" => description[:es],
                "description_ca" => description[:ca],
                "file" => file,
                "link" => link,
                "attachment_collection_id" => attachment_collection_id
              } }
          end

          it { is_expected.to be_valid }
        end
      end

      context "when attaching a link" do
        subject(:form) do
          described_class.from_params(
            attributes
          ).with_context(
            attached_to:,
            current_organization: organization
          )
        end

        let(:attached_to) do
          create(:participatory_process, organization:)
        end

        let(:title) do
          {
            en: "My attachment",
            es: "Mi adjunto",
            ca: "EL meu adjunt"
          }
        end
        let(:description) do
          {
            en: "My attachment description",
            es: "Descripción de mi adjunto",
            ca: "Descripció del meu adjunt"
          }
        end

        let(:file) { nil }
        let(:link) { "https://github.com/decidim/decidim" }
        let(:attachment_collection) { create(:attachment_collection, collection_for: attached_to) }
        let(:attachment_collection_id) { attachment_collection.id }
        let(:organization) { create(:organization) }

        let(:attributes) do
          {
            "attachment" => {
              "title_en" => title[:en],
              "title_es" => title[:es],
              "title_ca" => title[:ca],
              "description_en" => description[:en],
              "description_es" => description[:es],
              "description_ca" => description[:ca],
              "file" => file,
              "link" => link,
              "attachment_collection_id" => attachment_collection_id
            }
          }
        end

        it { is_expected.to be_valid }

        context "when link and file are not present" do
          let(:link) { nil }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end
end
