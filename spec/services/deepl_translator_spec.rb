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
    let(:translate_request) { instance_double(DeepL::Requests::Translate, request: translation) }
    let(:api) { instance_double(DeepL::API) }
    let(:translate_request) { instance_double(DeepL::Requests::Translate, request: translation) }

    before do
      allow(Decidim).to receive(:machine_translation_service_klass).and_return(DeeplTranslator)
      allow(DeepL::API).to receive(:new).and_return(api)
      allow(DeepL::Requests::Translate).to receive(:new).and_return(translate_request)
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
        let(:translate_request) { instance_double(DeepL::Requests::Translate, request: nil) }

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

      context "when DeepL raises a non-quota error" do
        before do
          allow(DeepL::Requests::Translate).to receive(:new).and_raise(StandardError, "API failure")
        end

        it "logs the error and re-raises" do
          expect(Rails.logger).to receive(:error).with(/\[DeeplTranslator\] StandardError - API failure/)
          expect { subject }.to raise_error(StandardError, "API failure")
        end
      end

      context "when DeepL raises QuotaExceeded" do
        before do
          allow(DeepL::Requests::Translate).to receive(:new).and_raise(DeepL::Exceptions::QuotaExceeded.new("Quota exceeded"))
        end

        it "logs the error and returns nil" do
          expect(Rails.logger).to receive(:error).with(/\[DeeplTranslator\] Quota exceeded/)
          expect(subject).to be_nil
        end
      end

      context "when translation succeeds" do
        it "enqueues MachineTranslationSaveJob with correct arguments" do
          expect(Decidim::MachineTranslationSaveJob).to receive(:perform_later).with(
            process,
            "title",
            target_locale,
            "Nouveau Titre"
          )
          subject
        end
      end

      context "when text is blank but not empty" do
        let(:text) { "   " }

        it "does not enqueue a job" do
          expect(Decidim::MachineTranslationSaveJob).not_to receive(:perform_later)
          expect(subject).to be_nil
        end
      end

      context "when translation text is blank" do
        let(:translate_request) { instance_double(DeepL::Requests::Translate, request: double("translation", text: "")) }

        it "does not enqueue a job" do
          expect(Decidim::MachineTranslationSaveJob).not_to receive(:perform_later)
          expect(subject).to be_nil
        end
      end

      context "when DeepL raises EOFError" do
        before do
          allow(DeepL::Requests::Translate).to receive(:new).and_raise(EOFError, "end of file reached")
        end

        it "logs the error and re-raises" do
          expect(Rails.logger).to receive(:error).with(/\[DeeplTranslator\] EOFError - end of file reached/)
          expect { subject }.to raise_error(EOFError)
        end
      end

      context "when DeepL raises IOError" do
        before do
          allow(DeepL::Requests::Translate).to receive(:new).and_raise(IOError, "stream closed in another thread")
        end

        it "logs the error and re-raises" do
          expect(Rails.logger).to receive(:error).with(/\[DeeplTranslator\] IOError - stream closed in another thread/)
          expect { subject }.to raise_error(IOError)
        end
      end
    end
  end
end
