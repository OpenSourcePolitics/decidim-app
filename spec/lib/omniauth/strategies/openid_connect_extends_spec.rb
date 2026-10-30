# frozen_string_literal: true

require "spec_helper"

module OmniAuth
  module Strategies
    RSpec.describe OpenIDConnect do
      subject(:strategy) { described_class.new(app, options) }

      let(:app) { ->(_env) { [200, {}, ["app"]] } }
      let(:options) do
        {
          path_prefix: "/users/auth",
          issuer:,
          setup:,
          client_options: { identifier: "dummy", end_session_endpoint: },
          post_logout_redirect_uri: "https://decidim.example.org"
        }
      end
      let(:issuer) { "https://idp.example.org" }
      let(:setup) { nil }
      let(:end_session_endpoint) { "https://idp.example.org/logout" }
      let(:session) { { "session_id" => "abc123" } }
      let(:path) { "/processes" }
      let(:env) { Rack::MockRequest.env_for(path, :method => "GET", "rack.session" => session) }

      let(:id_token_attributes) { { sub: "user-1", email: "id_token@example.org" } }
      let(:userinfo_attributes) { { sub: "user-1", name: "Jane Doe", given_name: "Jane", family_name: "Doe", email: "jane@example.org" } }
      let(:id_token) { "header.payload.signature" }
      let(:userinfo_response) { instance_double(::OpenIDConnect::ResponseObject::UserInfo, raw_attributes: userinfo_attributes) }
      let(:access_token) { double("access_token", id_token:, userinfo!: userinfo_response) }

      before do
        allow(strategy).to receive(:access_token).and_return(access_token)
        allow(strategy).to receive(:decode_id_token).with(id_token).and_return(double(raw_attributes: id_token_attributes))
      end

      it "adds a logout_policy option defaulting to none" do
        expect(strategy.options.logout_policy).to eq("none")
      end

      describe "#user_info" do
        it "merges the userinfo response with the decoded ID token, the ID token taking precedence" do
          expect(strategy.user_info).to be_a(::OpenIDConnect::ResponseObject::UserInfo)
          expect(strategy.user_info.name).to eq("Jane Doe")
          expect(strategy.user_info.email).to eq("id_token@example.org")
        end

        it "is memoized" do
          strategy.user_info
          strategy.user_info

          expect(access_token).to have_received(:userinfo!).once
        end

        context "when the userinfo endpoint answers with a signed JWT" do
          let(:userinfo_jwt) { "userinfo.jwt.signature" }
          let(:access_token) { double("access_token", id_token:, userinfo!: userinfo_jwt) }

          before do
            allow(strategy).to receive(:decode_id_token).with(userinfo_jwt).and_return(double(raw_attributes: userinfo_attributes))
          end

          it "decodes it before merging" do
            expect(strategy.user_info.name).to eq("Jane Doe")
            expect(strategy.user_info.email).to eq("id_token@example.org")
          end
        end

        context "without ID token" do
          let(:access_token) { double("access_token", id_token: nil, userinfo!: userinfo_response) }

          it "returns the userinfo response as is" do
            expect(strategy.user_info).to eq(userinfo_response)
          end
        end
      end

      describe "#user_info_name" do
        it "returns the name claim" do
          expect(strategy.user_info_name).to eq("Jane Doe")
        end

        context "without name claim" do
          let(:userinfo_attributes) { { sub: "user-1", given_name: "Jane", family_name: "Smith" } }

          it "builds it from the given and family names" do
            expect(strategy.user_info_name).to eq("Jane Smith")
          end
        end
      end

      describe "#info" do
        it "builds the info hash from the user info" do
          expect(strategy.info).to include(
            name: "Jane Doe",
            email: "id_token@example.org",
            first_name: "Jane",
            last_name: "Doe",
            urls: { website: nil }
          )
        end

        context "without name claim" do
          let(:userinfo_attributes) { { sub: "user-1", given_name: "Jane", family_name: "Smith" } }

          it "uses the given and family names" do
            expect(strategy.info[:name]).to eq("Jane Smith")
          end
        end
      end

      describe "#end_session_callback_value and #end_session_callback?" do
        before { strategy.instance_variable_set(:@env, env) }

        it "ties the callback to the provider and the session" do
          expect(strategy.end_session_callback_value).to eq("openid_connect--abc123")
        end

        it "is false when no logout was initiated" do
          expect(strategy.end_session_callback?).to be(false)
        end

        context "when a logout was initiated in this session" do
          let(:session) { { "session_id" => "abc123", "omniauth.logout.callback" => "openid_connect--abc123" } }

          it { expect(strategy.end_session_callback?).to be(true) }
        end
      end

      describe "#end_session_uri" do
        before { allow(strategy).to receive(:credentials).and_return(id_token: "the-id-token") }

        it "adds the ID token hint and the post logout redirect URI" do
          uri = URI(strategy.end_session_uri)

          expect(uri.to_s).to start_with(end_session_endpoint)
          expect(URI.decode_www_form(uri.query).to_h).to eq(
            "id_token_hint" => "the-id-token",
            "post_logout_redirect_uri" => "https://decidim.example.org"
          )
        end

        context "with an invalid end session endpoint" do
          let(:end_session_endpoint) { "not a url" }

          it { expect(strategy.end_session_uri).to be_nil }
        end

        context "without end session endpoint" do
          let(:end_session_endpoint) { nil }

          it { expect(strategy.end_session_uri).to be_nil }
        end
      end

      describe "#other_phase" do
        # #call dups the strategy and would drop the stubs, so #call! is used instead.
        subject(:response) { strategy.call!(env) }

        context "when the request is not a logout" do
          it "passes the request through to the app" do
            expect(response).to eq([200, {}, ["app"]])
          end

          context "when the app raises" do
            let(:app) { ->(_env) { raise ActionController::InvalidAuthenticityToken } }

            it "does not hide the origin of the error in the logged backtrace" do
              exception = begin
                response
              rescue ActionController::InvalidAuthenticityToken => e
                e
              end

              wrapper = ActionDispatch::ExceptionWrapper.new(Rails.backtrace_cleaner, exception)

              expect(wrapper.application_trace).to be_empty
              expect(wrapper.exception_trace.first).to start_with("spec/lib/omniauth/strategies/openid_connect_extends_spec.rb")
            end
          end
        end

        context "when the request is a logout" do
          let(:path) { "/users/auth/openid_connect/logout" }

          before { allow(strategy).to receive(:credentials).and_return(id_token: "the-id-token") }

          it "redirects to the end session endpoint and remembers the logout in session" do
            status, headers, = response

            expect(status).to eq(302)
            expect(headers["Location"]).to start_with("#{end_session_endpoint}?id_token_hint=the-id-token")
            expect(session["omniauth.logout.callback"]).to eq("openid_connect--abc123")
          end

          context "with a setup" do
            let(:setup) { double(call: nil) }

            it "runs it" do
              response

              expect(setup).to have_received(:call).with(env)
            end
          end

          context "without issuer" do
            let(:issuer) { nil }

            before do
              allow(strategy).to receive(:issuer).and_return("https://discovered.example.org")
            end

            it "resolves it" do
              response

              expect(strategy.options.issuer).to eq("https://discovered.example.org")
            end
          end

          context "without end session endpoint" do
            let(:end_session_endpoint) { nil }

            it "passes the request through to the app" do
              expect(response).to eq([200, {}, ["app"]])
            end
          end

          context "when coming back from the identity provider" do
            let(:session) { { "session_id" => "abc123", "omniauth.logout.callback" => "openid_connect--abc123" } }

            it "clears the logout marker and redirects to the Decidim sign out" do
              status, headers, = response

              expect(status).to eq(302)
              expect(headers["Location"]).to eq("/users/sign_out")
              expect(session).not_to have_key("omniauth.logout.callback")
            end
          end
        end
      end
    end
  end
end
