# frozen_string_literal: true

require "spec_helper"

require "decidim/content_fixer"

describe Decidim::ContentFixer do
  subject { described_class.new(content, deprecated_endpoint, logger) }

  let(:logger) { Rails.logger }
  let(:deprecated_endpoint) { "s3.decidim.org" }
  let(:invalid_resource) { create(:comment, body: invalid_body_comment) }
  let(:invalid_body_comment) { { en: "<p>Here is a not valid comment with <a href='#{deprecated_url}'>Link text</a></p>" } }
  let(:content) { "<p>Here is a not valid comment with <a href='#{deprecated_url}'>Link text</a></p>" }
  let(:deprecated_url) { "https://#{deprecated_endpoint}/xxxx?response-content-disposition=inline%3Bfilename%3D\"BuPa23_reglement-interieur.pdf\"%3Bfilename*%3DUTF-8''BuPa23_r%25C3%25A8glement-int%25C3%25A9rieur.pdf&response-content-type=application%2Fpdf" }
  let!(:blob) { ActiveStorage::Blob.create_after_upload!(filename: "BuPa23_reglement-interieur.pdf", io: File.open("spec/fixtures/BuPa23_reglement-interieur.pdf"), content_type: "application/pdf") }
  let(:blob_path) { Rails.application.routes.url_helpers.rails_blob_path(ActiveStorage::Blob.find(blob.id), only_path: true) }

  describe "#repair" do
    it "returns the repaired content" do
      replaced_content = subject.repair

      expect(replaced_content).to include(blob_path)
      expect(replaced_content).not_to include(deprecated_endpoint)
    end

    context "when content is a hash" do
      let(:content) { { en: "<p>Here is a not valid comment with <a href='#{deprecated_url}'>Link text</a></p>" } }

      it "returns the repaired content" do
        replaced_content = subject.repair

        expect(replaced_content[:en]).to include(blob_path)
        expect(replaced_content[:en]).not_to include(deprecated_endpoint)
      end
    end

    context "when content is an array" do
      let(:content) { ["<p>Here is a not valid comment with <a href='#{deprecated_url}'>Link text</a></p>"] }

      it "returns the repaired content" do
        replaced_content = subject.repair

        expect(replaced_content.first).to include(blob_path)
        expect(replaced_content.first).not_to include(deprecated_endpoint)
      end
    end

    context "when content is not a string, hash or array" do
      let(:content) { 1 }

      it "raises an error" do
        expect(subject.repair).to eq(1)
      end
    end
  end

  describe "#find_and_replace" do
    it "replaces the deprecated url with the new url" do
      replaced_content = subject.find_and_replace(content)

      expect(replaced_content).to start_with("<p")
      expect(replaced_content).to include(blob_path)
      expect(replaced_content).not_to include(deprecated_endpoint)
    end

    context "when content contains an image" do
      let(:content) { "<img src='#{deprecated_url}'/>" }

      it "replaces the deprecated url with the new url" do
        replaced_content = subject.find_and_replace(content)

        expect(replaced_content).to start_with("<img")
        expect(replaced_content).to include(blob_path)
        expect(replaced_content).not_to include(deprecated_endpoint)
      end
    end

    context "when content in not wrapped in a paragraph" do
      let(:content) { "Here is a not valid comment with <a href='#{deprecated_url}'>Link text</a>" }

      it "replaces the deprecated url with the new url" do
        replaced_content = subject.find_and_replace(content)

        expect(replaced_content).not_to start_with("<p")
        expect(replaced_content).to include(blob_path)
        expect(replaced_content).not_to include(deprecated_endpoint)
      end
    end

    context "when content is nil" do
      let(:content) { nil }

      it "returns an empty string" do
        expect(subject.find_and_replace(content)).to be_nil
      end
    end

    context "when content is an integer" do
      let(:content) { 1 }

      it "returns an empty string" do
        expect(subject.find_and_replace(content)).to eq(1)
      end
    end
  end

  describe "#new_source" do
    it "returns the new source for the given url" do
      expect(subject.new_source(deprecated_url)).to eq(blob_path)
    end

    context "when url is not a direct link" do
      let(:deprecated_url) { "https://#{deprecated_endpoint}/rails/active_storage/representations/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBY3c9IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--0dd7fba2bf600153aca7a8ada9d0b568010c7d1c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCam9TY21WemFYcGxYM1J2WDJacGRGc0hNR2tCN1E9PSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--4e2c28b6f31f9da4a43a726c999148c0062324fa/BuPa23_reglement-interieur.pdf" }

      it "returns the new source for the given url" do
        expect(subject.new_source(deprecated_url)).to eq(blob_path)
      end
    end

    context "when url is nil" do
      let(:deprecated_url) { nil }

      it "returns nil" do
        expect(subject.new_source(deprecated_url)).to be_nil
      end
    end
  end

  describe "#blobs" do
    it "returns an array filename and id" do
      expect(subject.blobs).to eq([[blob.filename.to_s, blob.id]])
    end
  end

  describe "#wrapped_in_paragraph?" do
    it "returns true if content is wrapped in a paragraph" do
      expect(subject.nokogiri_will_wrap_with_p?(content)).to be(false)
    end

    context "when content is not wrapped in a paragraph" do
      let(:content) { "My link is <a href='#{deprecated_url}'>Link text</a>" }

      it "returns false" do
        expect(subject.nokogiri_will_wrap_with_p?(content)).to be(true)
      end
    end
  end

  describe "#find_service_url_for_blob" do
    it "returns the service url for the given blob" do
      expect(subject.find_service_url_for_blob(blob.id)).to eq(blob_path)
    end

    context "when blob is not found" do
      it "returns nil" do
        expect(subject.find_service_url_for_blob(blob.id + 1)).to be_nil
      end
    end
  end
end
