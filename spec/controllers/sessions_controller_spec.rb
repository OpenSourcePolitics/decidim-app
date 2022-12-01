# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Devise
    describe SessionsController, type: :controller do
      routes { Decidim::Core::Engine.routes }

      describe "after_sign_in_path_for" do
        subject { controller.after_sign_in_path_for(user) }

        before do
          request.env["decidim.current_organization"] = user.organization
        end

        context "when the given resource is a user" do
          context "and is an admin" do
            let(:user) { build(:user, :admin, sign_in_count: 1) }

            before do
              controller.store_location_for(user, account_path)
            end

            it { is_expected.to eq account_path }
          end

          context "and is not an admin" do
            context "when it is the first time to log in" do
              let(:user) { build(:user, :confirmed, sign_in_count: 1) }

              context "when there are authorization handlers" do
                before do
                  allow(user.organization).to receive(:available_authorizations)
                    .and_return(["dummy_authorization_handler"])
                end

                it { is_expected.to eq("/authorizations/first_login") }

                context "when there's a pending redirection" do
                  before do
                    controller.store_location_for(user, account_path)
                  end

                  it { is_expected.to eq account_path }
                end

                context "when the user hasn't confirmed their email" do
                  before do
                    user.confirmed_at = nil
                  end

                  it { is_expected.to eq("/") }
                end

                context "when the user is blocked" do
                  before do
                    user.blocked = true
                  end

                  it { is_expected.to eq("/") }
                end

                context "when the user is not blocked" do
                  before do
                    user.blocked = false
                  end

                  it { is_expected.to eq("/authorizations/first_login") }
                end
              end

              context "and otherwise", with_authorization_workflows: [] do
                before do
                  allow(user.organization).to receive(:available_authorizations).and_return([])
                end

                it { is_expected.to eq("/") }
              end

              context "and authorization handler is skipped" do
                before do
                  allow(ENV).to receive(:[]).with("SKIP_FIRST_LOGIN_AUTHORIZATION").and_return("true")
                end

                it { is_expected.to eq("/") }
              end
            end

            context "and it's not the first time to log in" do
              let(:user) { build(:user, sign_in_count: 2) }

              it { is_expected.to eq("/") }
            end
          end
        end
      end

      describe "DELETE destroy" do
        let(:organization) { create(:organization) }
        let(:user) { create(:user, :confirmed, organization: organization) }

        before do
          request.env["decidim.current_organization"] = organization
          request.env["devise.mapping"] = ::Devise.mappings[:user]

          sign_in user
        end

        it "clears the current user" do
          delete :destroy

          expect(controller.current_user).to be_nil
        end

        context "when France Connect is enabled" do
          let(:organization) { create(:organization, omniauth_settings: omniauth_settings) }
          let(:omniauth_settings) do
            { "omniauth_settings_france_connect_enabled": true }
          end

          before do
            stub_request(:get, /test-france-connect.fr/).
              with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" })
                                                        .to_return(status: 200, body: "", headers: {})

            request.env["decidim.current_organization"] = user.organization
            request.env["devise.mapping"] = ::Devise.mappings[:user]

            sign_in user
          end

          it "logout user from France Connect" do
            delete :destroy, session: { "omniauth.france_connect.end_session_uri" => "http://test-france-connect.fr/" }

            expect(controller.current_user).to be_nil
            expect(controller).to redirect_to("http://test-france-connect.fr/")
            expect(session["flash"]["flashes"]["notice"]).to eq("Signed out successfully.")
          end

          context "and France Connect logout session is not present" do
            it "logout user from application" do
              delete :destroy

              expect(controller.current_user).to be_nil
              expect(controller).not_to redirect_to("http://test-france-connect.fr/")
              expect(controller).to redirect_to("http://test.host/")
              expect(session["flash"]["flashes"]["notice"]).to eq("Signed out successfully.")
            end
          end
        end
      end
    end
  end
end
