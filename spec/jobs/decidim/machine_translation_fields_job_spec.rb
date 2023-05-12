# frozen_string_literal: true

require "spec_helper"
require "deepl"

module Decidim
  describe MachineTranslationFieldsJob do
    let(:title) { { en: "New Title" } }
    let(:process) { build :participatory_process, title: title }
    let(:target_locale) { "ca" }
    let(:source_locale) { "en" }
    let(:url) { "https://dummy_url.org" }
    let(:translation) { double("translation", text: "Nou títol") }

    before do
      allow(Decidim).to receive(:machine_translation_service_klass).and_return(DeeplTranslator)
      allow(DeepL).to receive(:translate).with(title[source_locale.to_sym], source_locale, target_locale).and_return(translation)
    end

    describe "When fields job is executed" do
      before do
        clear_enqueued_jobs
      end

      it "calls DeeplTranslator to create machine translations" do
        expect(DeeplTranslator).to receive(:new).with(
          process,
          "title",
          process["title"][source_locale],
          target_locale,
          source_locale
        ).and_call_original

        process.save

        MachineTranslationFieldsJob.perform_now(
          process,
          "title",
          process["title"][source_locale],
          target_locale,
          source_locale
        )
      end
    end
  end
end
