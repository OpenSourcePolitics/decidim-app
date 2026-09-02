# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe OmniauthHelper do
    before { Rails.cache.clear }

    shared_context "with a stubbed organization" do
      let(:organization) { create(:organization, host: "test-#{SecureRandom.hex(4)}.org") }
      let(:enabled_providers) { {} }

      before do
        allow(helper).to receive(:current_organization).and_return(organization)
        allow(organization).to receive(:enabled_omniauth_providers).and_return(enabled_providers)
      end
    end

    describe "#normalize_provider_name" do
      context "when provider is google_oauth2" do
        it "returns just google" do
          expect(helper.normalize_provider_name(:google_oauth2)).to eq("google")
        end
      end

      context "when provider is twitter" do
        it "returns x" do
          expect(helper.normalize_provider_name(:twitter)).to eq("x")
        end
      end

      context "when provider is a composed name" do
        it "truncates to the first segment (used for CSS classes only, never shown to users)" do
          expect(helper.normalize_provider_name(:cultuur_connect)).to eq("cultuur")
          expect(helper.normalize_provider_name(:france_connect)).to eq("france")
        end
      end
    end

    describe "#omniauth_provider_label" do
      include_context "with a stubbed organization"

      context "when a Term Customizer override exists in the database" do
        let(:enabled_providers) { { publik: {} } }
        let(:key) { "decidim.devise.shared.links.provider_display_name_publik" }
        let(:translation_set) { create(:translation_set) }
        let!(:translation) { create(:translation, translation_set:, key:, value: "Login with MyPublik") }

        it "detects the override exists" do
          expect(helper.send(:term_customizer_override?, key)).to be(true)
        end
      end

      context "when I18n resolves a Term Customizer override for the provider" do
        let(:enabled_providers) { { publik: {} } }
        let(:key) { "decidim.devise.shared.links.provider_display_name_publik" }

        before do
          allow(helper).to receive(:term_customizer_override?).with(key).and_return(true)
          allow(I18n).to receive(:t).with(key, provider: "Publik").and_return("Login with MyPublik")
        end

        it "returns that translation, taking priority over display_name and the humanized fallback" do
          expect(helper.omniauth_provider_label(:publik)).to eq("Login with MyPublik")
        end
      end

      context "when no Term Customizer translation exists but display_name is configured" do
        let(:enabled_providers) { { cultuur_connect: { display_name: "Mon SSO" } } }

        it "returns the configured display_name" do
          expect(helper.omniauth_provider_label(:cultuur_connect)).to eq("Mon SSO")
        end
      end

      context "when nothing is configured" do
        let(:enabled_providers) { { cultuur_connect: {} } }

        it "returns the full humanized provider name, not truncated" do
          expect(helper.omniauth_provider_label(:cultuur_connect)).to eq("Cultuur Connect")
        end
      end

      context "when provider is twitter with nothing configured" do
        let(:enabled_providers) { { twitter: {} } }

        it "returns X" do
          expect(helper.omniauth_provider_label(:twitter)).to eq("X")
        end
      end

      context "when provider is google_oauth2 with nothing configured" do
        let(:enabled_providers) { { google_oauth2: {} } }

        it "returns Google, not Google Oauth2" do
          expect(helper.omniauth_provider_label(:google_oauth2)).to eq("Google")
        end
      end
    end

    describe "#full_image_button?" do
      include_context "with a stubbed organization"

      context "when both icon_path and icon_hover_path are configured" do
        let(:enabled_providers) { { openid_connect: { icon_path: "a.svg", icon_hover_path: "b.svg" } } }

        it "returns true" do
          expect(helper.full_image_button?(:openid_connect)).to be(true)
        end
      end

      context "when only icon_path is configured" do
        let(:enabled_providers) { { openid_connect: { icon_path: "a.svg" } } }

        it "returns false" do
          expect(helper.full_image_button?(:openid_connect)).to be(false)
        end
      end

      context "when provider is france_connect with no icon configured at all" do
        let(:enabled_providers) { { france_connect: {} } }

        it "returns true, using the hardcoded default icons" do
          expect(helper.full_image_button?(:france_connect)).to be(true)
        end
      end
    end

    describe "#oauth_icon" do
      include_context "with a stubbed organization"

      context "when Decidim.omniauth_providers is not defined on this Decidim version" do
        let(:enabled_providers) { { cultuur_connect: {} } }

        before do
          allow(Decidim).to receive(:respond_to?).with(:omniauth_providers).and_return(false)
        end

        it "does not raise and falls back to the generic icon" do
          expect { helper.oauth_icon(:cultuur_connect) }.not_to raise_error
        end
      end

      context "when the provider has an icon_path configured" do
        let(:enabled_providers) { { facebook: { icon_path: "facebook.svg" } } }

        it "renders the external icon" do
          expect(helper).to receive(:external_icon).with("facebook.svg")
          helper.oauth_icon(:facebook)
        end
      end

      context "when nothing is configured and the guessed icon name isn't registered" do
        let(:enabled_providers) { { openid_connect: {} } }

        before do
          allow(Decidim.icons).to receive(:all).and_return({})
        end

        it "falls back to the hardcoded fallback icon name" do
          expect(helper).to receive(:icon).with(OmniauthHelperExtends::FALLBACK_ICON_NAME)
          helper.oauth_icon(:openid_connect)
        end
      end
    end
  end
end
