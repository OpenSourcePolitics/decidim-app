# frozen_string_literal: true

require "spec_helper"
require "decidim/translator_configuration_helper"

RSpec.describe Decidim::TranslatorConfigurationHelper do
  let!(:original_queue_adapter) { Rails.configuration.active_job.queue_adapter }
  let!(:original_enable_machine_translations) { Decidim.enable_machine_translations }
  let(:with_incompatible_backend) { Rails.configuration.active_job.queue_adapter = :async }
  let(:with_compatible_backend) { Rails.configuration.active_job.queue_adapter = :something }
  let(:with_translations_enabled) { Decidim.enable_machine_translations = true }
  let(:with_translations_disabled) { Decidim.enable_machine_translations = false }

  after do
    Rails.configuration.active_job.queue_adapter = original_queue_adapter
    Decidim.enable_machine_translations = original_enable_machine_translations
  end

  describe ".able_to_seed?" do
    context "when Decidim translations are enabled" do
      before { with_translations_enabled }

      context "when the backend is 'async'" do
        before { with_incompatible_backend }

        it "raises an error" do
          expect do
            Decidim::TranslatorConfigurationHelper.able_to_seed?
          end.to raise_error RuntimeError, /^You can't seed the database/
        end
      end

      context "when the backend is not 'async'" do
        before { with_compatible_backend }

        it "returns nil" do
          expect(Decidim::TranslatorConfigurationHelper.able_to_seed?).to be_nil
        end
      end
    end

    context "when Decidim translations are disabled" do
      before { with_translations_disabled }

      it "returns true" do
        expect(Decidim::TranslatorConfigurationHelper.able_to_seed?).to be true
      end
    end
  end

  describe ".compatible_backend" do
    context "with an 'async' backend" do
      before { with_incompatible_backend }

      it "returns false" do
        expect(Decidim::TranslatorConfigurationHelper.compatible_backend?).to be false
      end
    end

    context "with another backend" do
      before { with_compatible_backend }

      it "returns true" do
        expect(Decidim::TranslatorConfigurationHelper.compatible_backend?).to be true
      end
    end
  end

  describe ".translator_activated?" do
    context "when translations are active" do
      before { with_translations_enabled }

      it "returns true" do
        expect(Decidim::TranslatorConfigurationHelper.translator_activated?).to be true
      end
    end

    context "when translations are inactive" do
      before { with_translations_disabled }

      it "returns true" do
        expect(Decidim::TranslatorConfigurationHelper.translator_activated?).to be false
      end
    end
  end
end
