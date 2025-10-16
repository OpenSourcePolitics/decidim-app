# frozen_string_literal: true

require "spec_helper"
require "deepl"

module Decidim
  describe DeeplTranslator do
    let(:title) { { en: "New Title" } }
    let(:process) { build(:participatory_process, title:) }
    let(:target_locale) { "fr" }
    let(:source_locale) { "en" }
    let(:translation) { double("translation", text: "Nouveau Titre") }

    before do
      allow(Decidim).to receive(:machine_translation_service_klass).and_return(DeeplTranslator)
      allow(::DeepL).to receive(:translate).with(title[source_locale.to_sym], source_locale, target_locale).and_return(translation)
    end

    describe "When fields job is executed" do
      before { clear_enqueued_jobs }

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

    describe "#translate" do
      subject { DeeplTranslator.new(process, "title", text, target_locale, source_locale).translate }
      let(:text) { title[source_locale.to_sym] }

      context "when translation is nil" do
        before { allow(::DeepL).to receive(:translate).and_return(nil) }

        it "does not enqueue a job" do
          expect(Decidim::MachineTranslationSaveJob).not_to receive(:perform_later)
          expect(subject).to be_nil
        end
      end

      context "when text is empty" do
        let(:text) { "" }

        it "does not enqueue a job" do
          expect(Decidim::MachineTranslationSaveJob).not_to receive(:perform_later)
          expect(subject).to be_nil
        end
      end

      context "when DeepL raises an error" do
        before { allow(::DeepL).to receive(:translate).and_raise(StandardError, "API failure") }

        it "logs the error and flow does not break" do
          expect(Rails.logger).to receive(:error).with(/\[DeeplTranslator\] StandardError - API failure/)
          expect(subject).to be_nil
        end
      end
    end
  end
end
