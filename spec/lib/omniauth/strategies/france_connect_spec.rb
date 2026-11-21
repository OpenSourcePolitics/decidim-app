# frozen_string_literal: true

require "spec_helper"
require "omniauth/strategies/france_connect"

module OmniAuth
  module Strategies
    RSpec.describe FranceConnect do
      subject(:strategy) do
        described_class.new(
          ->(_env) { [200, {}, ["app"]] },
          client_options: { identifier: "dummy", end_session_endpoint: "https://fc.example.org/session/end" },
          post_logout_redirect_uri: "https://decidim.example.org"
        )
      end

      let(:session) { { "session_id" => "abc123", "omniauth.id_token_hint" => "the-id-token" } }
      let(:env) { Rack::MockRequest.env_for("/", "rack.session" => session) }
      let(:end_session_uri) { strategy.end_session_uri }
      let(:query) { URI.decode_www_form(URI(end_session_uri).query).to_h }

      before do
        strategy.instance_variable_set(:@env, env)
        allow(strategy).to receive(:access_token)
      end

      describe "#end_session_uri" do
        it "adds the ID token hint kept in session, a state and the post logout redirect URI" do
          expect(end_session_uri).to start_with("https://fc.example.org/session/end?")
          expect(query).to include("id_token_hint" => "the-id-token", "post_logout_redirect_uri" => "https://decidim.example.org")
          expect(query["state"]).to be_present
          expect(session).not_to have_key("omniauth.id_token_hint")
        end

        context "without ID token hint in session" do
          let(:session) { { "session_id" => "abc123" } }

          it "omits it without requesting a token from the provider" do
            expect(query).not_to have_key("id_token_hint")
            expect(strategy).not_to have_received(:access_token)
          end
        end
      end
    end
  end
end
