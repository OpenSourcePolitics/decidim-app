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
  let(:valid_url) { "https://#{valid_endpoint}/xxxx?response-content-disposition=inline%3Bfilename%3D\"BuPa23_reglement-interieur.pdf\"%3Bfilename*%3DUTF-8''BuPa23_r%25C3%25A8glement-int%25C3%25A9rieur.pdf&response-content-type=application%2Fpdf" }
  let(:valid_endpoint) { "s3.valid.org" }
  let(:doc) { Nokogiri::HTML(content) }

  before do
    allow(ActiveStorage::Blob).to receive(:pluck).with(:filename, :id).and_return([["BuPa23_reglement-interieur.pdf", invalid_resource.id]])
    allow(ActiveStorage::Blob).to receive(:find).with(invalid_resource.id).and_return(double(service_url: valid_url))
  end

  describe "#repair" do
    it "returns the repaired content" do
      replaced_content = subject.repair

      expect(replaced_content).to include(valid_endpoint)
      expect(replaced_content).not_to include(deprecated_endpoint)
    end

    context "when content is a hash" do
      let(:content) { { en: "<p>Here is a not valid comment with <a href='#{deprecated_url}'>Link text</a></p>" } }

      it "returns the repaired content" do
        replaced_content = subject.repair

        expect(replaced_content[:en]).to include(valid_endpoint)
        expect(replaced_content[:en]).not_to include(deprecated_endpoint)
      end
    end

    context "when content is an array" do
      let(:content) { ["<p>Here is a not valid comment with <a href='#{deprecated_url}'>Link text</a></p>"] }

      it "returns the repaired content" do
        replaced_content = subject.repair

        expect(replaced_content.first).to include(valid_endpoint)
        expect(replaced_content.first).not_to include(deprecated_endpoint)
      end
    end

    context "when content is not a string, hash or array" do
      let(:content) { 1 }

      it "raises an error" do
        expect(subject.repair).to eq(nil)
      end
    end
  end

  describe "#replace_urls" do
    it "replaces the deprecated url with the new url" do
      subject.replace_urls(doc, "a")

      replaced_content = doc.css("body").inner_html

      expect(replaced_content).to include(valid_endpoint)
      expect(replaced_content).not_to include(deprecated_endpoint)
    end

    context "when content contains an image" do
      let(:content) { "<img src='#{deprecated_url}'/>" }

      it "replaces the deprecated url with the new url" do
        subject.replace_urls(doc, "img")

        replaced_content = doc.css("body").inner_html

        expect(replaced_content).to include(valid_endpoint)
        expect(replaced_content).not_to include(deprecated_endpoint)
      end
    end
  end

  describe "#new_source" do
    it "returns the new source for the given url" do
      expect(subject.new_source(deprecated_url)).to eq(valid_url)
    end

    context "when url is not a direct link" do
      let(:deprecated_url) { "https://#{deprecated_endpoint}/rails/active_storage/representations/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBY3c9IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--0dd7fba2bf600153aca7a8ada9d0b568010c7d1c/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCam9TY21WemFYcGxYM1J2WDJacGRGc0hNR2tCN1E9PSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--4e2c28b6f31f9da4a43a726c999148c0062324fa/BuPa23_reglement-interieur.pdf" }

      it "returns the new source for the given url" do
        expect(subject.new_source(deprecated_url)).to eq(valid_url)
      end
    end

    context "when url is nil" do
      let(:deprecated_url) { nil }

      it "returns nil" do
        expect(subject.new_source(deprecated_url)).to eq(nil)
      end
    end
  end

  describe "#blobs" do
    it "returns an array filename and id" do
      expect(subject.blobs).to eq([["BuPa23_reglement-interieur.pdf", invalid_resource.id]])
    end
  end

  describe "#wrapped_in_paragraph?" do
    it "returns true if content is wrapped in a paragraph" do
      expect(subject.wrapped_in_paragraph?(content)).to eq(true)
    end

    context "when content is not wrapped in a paragraph" do
      let(:content) { "<a href='#{deprecated_url}'>Link text</a>" }

      it "returns false" do
        expect(subject.wrapped_in_paragraph?(content)).to eq(false)
      end
    end
  end

  describe "#find_service_url_for_blob" do
    it "returns the service url for the given blob" do
      expect(subject.find_service_url_for_blob(invalid_resource.id)).to eq(valid_url)
    end
  end
end
