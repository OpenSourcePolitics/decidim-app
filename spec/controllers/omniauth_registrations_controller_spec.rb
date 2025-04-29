# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Decidim::Devise::OmniauthRegistrationsController, type: :controller do
    routes { Decidim::Core::Engine.routes }

    let(:organization) { create(:organization) }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["devise.mapping"] = ::Devise.mappings[:user]
    end

    describe "POST create" do
      let(:provider) { "facebook" }
      let(:uid) { "12345" }
      let(:email) { "user@from-facebook.com" }
      let!(:user) { create(:user, organization: organization, email: email) }

      before do
        request.env["omniauth.auth"] = {
          provider: provider,
          uid: uid,
          info: {
            name: "Facebook User",
            nickname: "facebook_user",
            email: email
          }
        }
        request.env["omniauth.strategy"] = OmniAuth::Strategies::Facebook.new({})
      end

      describe "#sign_in_and_redirect" do
        before do
          allow(controller).to receive(:sign_in_and_redirect) do |_user|
            strategy = request.env["omniauth.strategy"]

            provider = strategy&.name
            session["omniauth.provider"] = provider
            session["omniauth.#{provider}.logout_policy"] = strategy.options[:logout_policy] if strategy&.options.present? && strategy.options[:logout_policy].present?
            session["omniauth.#{provider}.logout_path"] = strategy.options[:logout_path] if strategy&.options.present? && strategy.options[:logout_path].present?

            true
          end
        end

        context "with full strategy and options" do
          let(:strategy) do
            double("OmniAuth::Strategy",
                   name: "facebook",
                   options: { logout_policy: "delete", logout_path: "/logout/facebook" })
          end

          before do
            request.env["omniauth.strategy"] = strategy
          end

          it "stores provider and logout options in session" do
            controller.send(:sign_in_and_redirect, user)

            expect(session["omniauth.provider"]).to eq("facebook")
            expect(session["omniauth.facebook.logout_policy"]).to eq("delete")
            expect(session["omniauth.facebook.logout_path"]).to eq("/logout/facebook")
          end
        end

        context "when strategy is nil" do
          before do
            request.env["omniauth.strategy"] = nil
          end

          it "does not raise and sets session accordingly" do
            expect do
              controller.send(:sign_in_and_redirect, user)
            end.not_to raise_error

            expect(session["omniauth.provider"]).to be_nil
          end
        end

        context "when strategy.options is nil" do
          let(:strategy) do
            double("OmniAuth::Strategy", name: "facebook", options: nil)
          end

          before do
            request.env["omniauth.strategy"] = strategy
          end

          it "does not raise and sets only the provider in session" do
            expect do
              controller.send(:sign_in_and_redirect, user)
            end.not_to raise_error

            expect(session["omniauth.provider"]).to eq("facebook")
            expect(session["omniauth.facebook.logout_policy"]).to be_nil
            expect(session["omniauth.facebook.logout_path"]).to be_nil
          end
        end

        context "when strategy.options is empty" do
          let(:strategy) do
            double("OmniAuth::Strategy", name: "facebook", options: {})
          end

          before do
            request.env["omniauth.strategy"] = strategy
          end

          it "sets only the provider in session without errors" do
            expect do
              controller.send(:sign_in_and_redirect, user)
            end.not_to raise_error

            expect(session["omniauth.provider"]).to eq("facebook")
            expect(session["omniauth.facebook.logout_policy"]).to be_nil
            expect(session["omniauth.facebook.logout_path"]).to be_nil
          end
        end
      end

      describe "#skip_first_login_authorization?" do
        around do |example|
          original = ENV.fetch("SKIP_FIRST_LOGIN_AUTHORIZATION", nil)
          example.run
          ENV["SKIP_FIRST_LOGIN_AUTHORIZATION"] = original
        end

        it "returns true when the env is set to true" do
          ENV["SKIP_FIRST_LOGIN_AUTHORIZATION"] = "true"
          expect(controller.send(:skip_first_login_authorization?)).to be true
        end

        it "returns false when the env is set to false" do
          ENV["SKIP_FIRST_LOGIN_AUTHORIZATION"] = "false"
          expect(controller.send(:skip_first_login_authorization?)).to be false
        end

        it "returns false when the env is not set" do
          ENV.delete("SKIP_FIRST_LOGIN_AUTHORIZATION")
          expect(controller.send(:skip_first_login_authorization?)).to be false
        end
      end

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

                context "when there is a pending redirection" do
                  before do
                    controller.store_location_for(user, account_path)
                  end

                  it { is_expected.to eq account_path }
                end

                context "when the user has not confirmed their email" do
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

                context "when skip_first_login_authorization? is true" do
                  before do
                    allow(controller).to receive(:skip_first_login_authorization?).and_return(true)
                  end

                  it { is_expected.to eq("/") }
                end

                context "when skip_first_login_authorization? is false" do
                  before do
                    allow(controller).to receive(:skip_first_login_authorization?).and_return(false)
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
            end

            context "and it is not the first time to log in" do
              let(:user) { build(:user, sign_in_count: 2) }

              it { is_expected.to eq("/") }
            end

            context "when the user is blocked and admin" do
              let(:user) { build(:user, :admin, blocked: true, sign_in_count: 1) }

              it { is_expected.to eq("/") }
            end

            context "when the user is blocked and not admin" do
              let(:user) { build(:user, blocked: true, sign_in_count: 1) }

              it { is_expected.to eq("/") }
            end
          end
        end
      end

      context "when the user has the account blocked" do
        let!(:user) { create(:user, organization: organization, email: email, blocked: true) }

        before do
          post :create
        end

        it "does not log in" do
          expect(controller).not_to be_user_signed_in
        end

        it "redirects to root" do
          expect(controller).to redirect_to(root_path)
        end

        it "shows an error message instead of notice" do
          expect(flash[:error]).to be_present
        end
      end

      context "when the unverified email address is already in use" do
        before do
          post :create
        end

        it "doesn't create a new user" do
          expect(User.count).to eq(1)
        end

        it "logs in" do
          expect(controller).to be_user_signed_in
        end
      end

      context "when the unverified email address is already in use but left unconfirmed" do
        before do
          user.update!(
            confirmation_sent_at: Time.now.utc - 1.year
          )
        end

        context "with the same email as from the identity provider" do
          before do
            post :create
          end

          it "logs in" do
            expect(controller).to be_user_signed_in
          end

          it "confirms the user account" do
            expect(controller.current_user).to be_confirmed
          end
        end

        context "with another email than the one from the identity provider" do
          let!(:identity) { create(:identity, user: user, uid: uid) }

          before do
            request.env["omniauth.auth"][:info][:email] = "omniauth@email.com"
          end

          it "doesn't log in" do
            post :create

            expect(controller).not_to be_user_signed_in
          end

          it "redirects to root" do
            post :create

            expect(controller).to redirect_to(root_path)
          end
        end
      end
    end
  end
end
