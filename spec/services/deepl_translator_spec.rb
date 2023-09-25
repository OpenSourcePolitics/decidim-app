# frozen_string_literal: true

require "spec_helper"

describe DeeplTranslator do
  subject { described_class.new(resource, field_name, text, target_locale, source_locale) }

  let(:resource) { create(:comment) }
  let(:field_name) { "body" }
  let(:text) { "This is a comment" }
  let(:response_text) { "Este es un comentario" }
  let(:target_locale) { "es" }
  let(:source_locale) { "en" }

  before do
    stub_request(:get, "https://translator.example.org/v2/languages").with(
      headers: {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "User-Agent" => "Ruby"
      }
    ).to_return(status: 200, body: JSON.dump([
                                               {
                                                 language: "BG",
                                                 name: "Bulgarian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "CS",
                                                 name: "Czech",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "DA",
                                                 name: "Danish",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "DE",
                                                 name: "German",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "EL",
                                                 name: "Greek",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "EN-GB",
                                                 name: "English (British)",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "EN-US",
                                                 name: "English (American)",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "ES",
                                                 name: "Spanish",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "ET",
                                                 name: "Estonian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "FI",
                                                 name: "Finnish",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "FR",
                                                 name: "French",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "HU",
                                                 name: "Hungarian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "ID",
                                                 name: "Indonesian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "IT",
                                                 name: "Italian",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "JA",
                                                 name: "Japanese",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "KO",
                                                 name: "Korean",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "LT",
                                                 name: "Lithuanian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "LV",
                                                 name: "Latvian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "NB",
                                                 name: "Norwegian (Bokmål)",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "NL",
                                                 name: "Dutch",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "PL",
                                                 name: "Polish",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "PT-BR",
                                                 name: "Portuguese (Brazilian)",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "PT-PT",
                                                 name: "Portuguese (European)",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "RO",
                                                 name: "Romanian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "RU",
                                                 name: "Russian",
                                                 supports_formality: true
                                               },
                                               {
                                                 language: "SK",
                                                 name: "Slovak",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "SL",
                                                 name: "Slovenian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "SV",
                                                 name: "Swedish",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "TR",
                                                 name: "Turkish",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "UK",
                                                 name: "Ukrainian",
                                                 supports_formality: false
                                               },
                                               {
                                                 language: "ZH",
                                                 name: "Chinese (simplified)",
                                                 supports_formality: false
                                               }
                                             ]), headers: {})

    stub_request(:post, "https://translator.example.org/v2/translate").with(
      body: { "source_lang" => "en", "target_lang" => "es", "text" => "This is a comment" },
      headers: {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Content-Type" => "application/x-www-form-urlencoded",
        "User-Agent" => "Ruby"
      }
    ).to_return(status: 200, body: JSON.dump({
                                               translations: [
                                                 {
                                                   detected_source_language: source_locale.upcase,
                                                   text: response_text
                                                 }
                                               ]
                                             }), headers: {})
  end

  describe "#deepl_translatable_locales" do
    it "returns an array of locales" do
      expect(subject.deepl_translatable_locales).to be_an(Array)
    end
  end

  describe "#translatable_locale?" do
    context "when the locale is translatable" do
      it "returns true" do
        expect(subject.translatable_locale?(target_locale)).to be(true)
      end
    end

    context "when the locale is not translatable" do
      let(:target_locale) { "sr" }

      it "returns false" do
        expect(subject.translatable_locale?(target_locale)).to be(false)
      end
    end
  end

  describe "#translate" do
    it "enqueues a job" do
      expect { subject.translate }.to have_enqueued_job(Decidim::MachineTranslationSaveJob).with(
        resource,
        field_name,
        target_locale,
        response_text
      )
    end

    context "when the locale is not translatable" do
      let(:target_locale) { "sr" }

      it "does not enqueue a job" do
        expect { subject.translate }.not_to have_enqueued_job(Decidim::MachineTranslationSaveJob)
      end
    end
  end
end
