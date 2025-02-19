# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe AccountController, type: :controller do
    routes { Decidim::Core::Engine.routes }

    let(:user) { create(:user, :confirmed, organization: organization) }
    let(:organization) { create(:organization) }

    before do
      request.env["decidim.current_organization"] = organization
      sign_in user
    end

    describe "DELETE destroy" do
      context "when FranceConnect is activated" do
        let(:organization) { create(:organization, omniauth_settings: omniauth_settings) }
        let(:omniauth_settings) do
          { omniauth_settings_france_connect_enabled: true }
        end

        before do
          stub_request(:get, /test-france-connect.fr/)
            .with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" })
            .to_return(status: 200, body: "", headers: {})

          request.env["decidim.current_organization"] = user.organization
          request.env["devise.mapping"] = ::Devise.mappings[:user]

          sign_in user
        end

        it "logout user from France Connect and deletes the account" do
          delete :destroy, session: { "omniauth.france_connect.end_session_uri" => "http://test-france-connect.fr/" }

          expect(controller.current_user).to be_nil
          expect(controller).to redirect_to("http://test-france-connect.fr/")
          expect(flash[:notice]).to eq("Your account was successfully deleted.")
        end

        context "and France Connect logout session is not present" do
          it "deletes the account" do
            delete :destroy

            expect(controller.current_user).to be_nil
            expect(controller).not_to redirect_to("http://test-france-connect.fr/")
            expect(flash[:notice]).to eq("Your account was successfully deleted.")
          end
        end
      end

      context "when another OmniAuth provider is activated" do
        let(:organization) { create(:organization, omniauth_settings: omniauth_settings) }
        let(:omniauth_settings) do
          { omniauth_settings_facebook_enabled: true }
        end

        before do
          request.env["decidim.current_organization"] = user.organization
          request.env["devise.mapping"] = ::Devise.mappings[:user]

          sign_in user
          session["omniauth.provider"] = :facebook
          session["omniauth.facebook.logout_policy"] = "session.destroy"
          session["omniauth.facebook.logout_path"] = "/logout"
        end

        it "logout user from OmniAuth provider and deletes the account" do
          delete :destroy

          expect(controller.current_user).to be_nil
          expect(controller).to redirect_to("http://test.host/users/auth/facebook/logout")
          expect(flash[:notice]).to eq("Your account was successfully deleted.")
        end
      end

      context "when no OmniAuth provider is activated" do
        it "deletes the account" do
          delete :destroy

          expect(controller.current_user).to be_nil
          expect(flash[:notice]).to eq("Your account was successfully deleted.")
        end
      end

      context "when account deletion fails" do
        before do
          allow_any_instance_of(Decidim::DestroyAccount).to receive(:call).and_return(:invalid)
        end

        it "does not delete the account and shows an error message" do
          delete :destroy

          expect(controller.current_user).not_to be_nil
        end
      end
    end
  end
end
