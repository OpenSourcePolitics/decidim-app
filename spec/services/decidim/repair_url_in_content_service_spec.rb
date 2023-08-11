# frozen_string_literal: true

require "spec_helper"

describe Decidim::RepairUrlInContentService do
  subject { described_class.run(deprecated_endpoint) }

  let(:deprecated_endpoint) { "s3.decidim.org" }
  let(:valid_endpoint) { "s3.valid.org" }
  let(:invalid_resource1) { create(:comment, body: invalid_body_comment) }
  let(:invalid_resource2) { create(:comment) }
  let(:invalid_body_comment) { { en: "<p>Here is a not valid comment with <a href='#{deprecated_url}'>Link text</a></p>" } }
  let(:deprecated_url) { "https://#{deprecated_endpoint}/xxxx?response-content-disposition=inline%3Bfilename%3D\"BuPa23_reglement-interieur.pdf\"%3Bfilename*%3DUTF-8''BuPa23_r%25C3%25A8glement-int%25C3%25A9rieur.pdf&response-content-type=application%2Fpdf" }
  let(:valid_url) { "https://#{valid_endpoint}/xxxx?response-content-disposition=inline%3Bfilename%3D\"BuPa23_reglement-interieur.pdf\"%3Bfilename*%3DUTF-8''BuPa23_r%25C3%25A8glement-int%25C3%25A9rieur.pdf&response-content-type=application%2Fpdf" }

  # rubocop:disable RSpec/AnyInstance
  before do
    allow_any_instance_of(Decidim::ContentFixer).to receive(:blobs).and_return([["BuPa23_reglement-interieur.pdf", invalid_resource1.id]])
    allow_any_instance_of(Decidim::ContentFixer).to receive(:find_service_url_for_blob).with(invalid_resource1.id).and_return(valid_url)
  end
  # rubocop:enable RSpec/AnyInstance

  describe "#run" do
    it "updates values from comments" do
      expect do
        subject
        invalid_resource1.reload
      end.to change(invalid_resource1, :body)

      expect(invalid_resource1.body["en"]).to include(valid_endpoint)
    end

    context "when invalid contains an image" do
      let(:invalid_body_comment) { { en: "<p>Here is a not valid comment with <img src='#{deprecated_url}'/></p>" } }

      it "updates values from comments" do
        expect do
          subject
          invalid_resource1.reload
        end.to change(invalid_resource1, :body)

        expect(invalid_resource1.body["en"]).to include(valid_endpoint)
      end
    end

    context "when deprecated url is not a direct link" do
      let(:deprecated_url) { "https://#{deprecated_endpoint}/rails/active_storage/representations/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBY3c9IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--0dd7fba2bf600153aca7a8ada9d0b568010c7d1c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCam9TY21WemFYcGxYM1J2WDJacGRGc0hNR2tCN1E9PSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--4e2c28b6f31f9da4a43a726c999148c0062324fa/BuPa23_reglement-interieur.pdf" }

      it "updates values from comments" do
        expect do
          subject
          invalid_resource1.reload
        end.to change(invalid_resource1, :body)

        expect(invalid_resource1.body["en"]).to include(valid_endpoint)
      end
    end

    context "when new link is nil" do
      let(:valid_url) { nil }

      it "does not update resources" do
        expect do
          subject
          invalid_resource1.reload
        end.not_to change(invalid_resource1, :body)
      end
    end

    context "when deprecated_endpoint is blank" do
      let(:deprecated_endpoint) { nil }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when resource text is not HTML" do
      let(:invalid_body_comment) { { en: "Here is a not valid comment with #{deprecated_url}" } }

      it "does not update resources" do
        expect do
          subject
          invalid_resource1.reload
        end.not_to change(invalid_resource1, :body)
      end
    end

    context "when resource is a ContentBlock" do
      let(:invalid_resource1) { create(:content_block, manifest_name: :html, scope_name: :homepage) }
      let(:invalid_html_content) { "<p><a href='#{deprecated_url}'><img src='#{deprecated_url}'/></a></p>" }

      let(:settings) do
        Decidim.available_locales.each_with_object({}) do |locale, hash|
          hash["html_content_#{locale}"] = invalid_html_content
        end
      end

      before do
        form = Decidim::Admin::ContentBlockForm.from_params(
          {
            content_block: {
              settings: settings,
              images: {}
            }
          }
        )
        Decidim::Admin::UpdateContentBlock.new(form, invalid_resource1, invalid_resource1.scope_name).call
      end

      it "updates values from content blocks" do
        expect do
          subject
          invalid_resource1.reload
        end.to change(invalid_resource1, :settings)

        expect(invalid_resource1.settings.html_content[:en]).to include(valid_endpoint)
      end
    end
  end

  describe "#models" do
    subject { described_class.new(deprecated_endpoint) }

    it "returns models" do
      [
        Decidim::Comments::Comment,
        Decidim::Proposals::Proposal,
        Decidim::ContentBlock
      ].each do |model|
        expect(subject.models).to include(model)
      end
    end
  end

  describe "#records_for" do
    subject { described_class.new(deprecated_endpoint).records_for(model) }

    let(:model) { Decidim::Comments::Comment }

    it "returns all records that have a column of type string jsonb or text" do
      expect(subject).to include(invalid_resource1)
      expect(subject).not_to include(invalid_resource2)
    end

    it "generates a unique SQL query" do
      expect(subject.to_sql).to eq("SELECT \"decidim_comments_comments\".* FROM \"decidim_comments_comments\" WHERE (((((decidim_commentable_type::text LIKE '%#{deprecated_endpoint}%') OR (decidim_root_commentable_type::text LIKE '%#{deprecated_endpoint}%')) OR (decidim_author_type::text LIKE '%#{deprecated_endpoint}%')) OR (body::text LIKE '%#{deprecated_endpoint}%')) OR (decidim_participatory_space_type::text LIKE '%#{deprecated_endpoint}%'))")
    end

    context "when model cannot be constantized" do
      let(:model) { "Decidim::Comments::NotExistingModel" }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end
  end
end
