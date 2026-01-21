# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe OmniauthHelper do
    let(:facebook_enabled) { true }
    let(:twitter_enabled) { true }
    let(:publik_enabled) { true }
    let(:secrets) do
      {
        omniauth: {
          facebook: { enabled: facebook_enabled },
          twitter: { enabled: twitter_enabled },
          publik: { enabled: publik_enabled }
        }
      }
    end

    before do
      allow(Rails.application).to receive(:secrets).and_return(secrets)
    end

    describe "#normalize_provider_name" do
      context "when provider is google_oauth2" do
        it "returns just google" do
          expect(helper.normalize_provider_name(:google_oauth2)).to eq("google")
        end
      end

      # context "when provider is publik" do
      #   let(:translation_set) { create(:translation_set) }
      #   let!(:translation) { create(:translation, key: "decidim.devise.shared.links.log_in_with_provider", value: "Login with MyPublik") }
      #
      #   before do
      #     allow(I18n).to receive(:t).with("decidim.devise.shared.links.log_in_with_provider").and_return("Login with MyPublik")
      #   end
      #
      #   it "returns the specific translation key" do
      #     expect(helper.normalize_provider_name(:publik)).to eq("Login with MyPublik")
      #   end
      # end
    end
  end
end
