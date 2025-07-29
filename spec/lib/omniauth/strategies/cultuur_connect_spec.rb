# frozen_string_literal: true

require "omniauth/strategies/cultuur_connect"
require "spec_helper"

class DummyApp
  def call(env); end
end

module OmniAuth
  module Strategies
    RSpec.describe CultuurConnect do
      subject do
        described_class.new(DummyApp.new).tap do |strategy|
          strategy.options.client_options.site = site
          strategy.options.client_id = "dummy_client_id"
          strategy.options.client_secret = "dummy_client_secret"
        end
      end
      let(:site) { "https://example.com" }

      it "returns correct strategy name" do
        expect(subject.options.name).to eq(:cultuur_connect)
      end

      it "returns option site" do
        expect(subject.options.client_options.site).to eq(site)
      end

      it "returns client_id" do
        expect(subject.options.client_id).to eq("dummy_client_id")
      end

      it "returns client_secret" do
        expect(subject.options.client_secret).to eq("dummy_client_secret")
      end

      describe "#build_access_token" do
        it "builds access token with correct params" do
          allow(subject).to receive(:callback_url).and_return("https://example.com/callback")
          allow(subject).to receive(:request).and_return(double(params: { "code" => "dummy_code" }))
          allow(subject).to receive(:client).and_return(double(auth_code: double(get_token: "dummy_token")))

          token = subject.send(:build_access_token)
          expect(token).to eq("dummy_token")
        end
      end

      describe "#raw_info" do
        it "decodes JWT token correctly" do
          allow(subject).to receive(:access_token).and_return(double(token: "dummy_jwt_token"))
          allow(JWT).to receive(:decode).and_return([{ "sub" => "123", "email" => "test@example.com" }])

          raw_info = subject.send(:raw_info)
          expect(raw_info["sub"]).to eq("123")
          expect(raw_info["email"]).to eq("test@example.com")
        end
      end

      describe "#info" do
        it "returns correct user info" do
          allow(subject).to receive(:raw_info).and_return({ "sub" => "123", "email" => "test@example.com", "firstname" => "John", "surname" => "Doe" })

          info = subject.send(:info)
          expect(info[:name]).to eq("John Doe")
          expect(info[:email]).to eq("test@example.com")
          expect(info[:nickname]).to eq("john_doe")
        end
      end
    end
  end
end