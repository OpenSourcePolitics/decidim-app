# frozen_string_literal: true

require "spec_helper"
require "decidim/translator_configuration_helper"

module Decidim
  describe TranslatorConfigurationHelper do
    let(:compatible_backend?) { true }
    let(:translator_activated?) { false }

    describe "When able_to_seed? is called" do
      before do
        allow(TranslatorConfigurationHelper).to receive(:compatible_backend?).and_return(compatible_backend?)
        allow(TranslatorConfigurationHelper).to receive(:translator_activated?).and_return(translator_activated?)
      end

      it "does not raise an error" do
        expect { TranslatorConfigurationHelper.able_to_seed? }.not_to raise_error
      end

      context "when translator is activated and backend is not compatible" do
        let(:translator_activated?) { true }
        let(:compatible_backend?) { false }

        it "raises an error" do
          expect { TranslatorConfigurationHelper.able_to_seed? }.to raise_error(RuntimeError, "You can't seed the database with machine translations enabled unless you use a compatible backend")
        end
      end
    end
  end
end
