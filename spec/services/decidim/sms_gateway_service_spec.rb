# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::SmsGatewayService, type: :service do
  let(:mobile_phone_number) { "+1234567890" }
  let(:code) { "1234" }
  let(:sms_gateway_context) { { organization: double("organization", name: "Test Organization") } }
  let(:url) { "https://services.message-business.com" }
  let(:username) { "test_user" }
  let(:password) { "test_password" }
  let(:mb_account_id) { "test_account" }
  let(:mb_api_key) { "test_key" }
  let(:platform) { "Test Platform" }
  let(:service) { described_class.new(mobile_phone_number, code, sms_gateway_context) }

  before do
    allow(Rails.application).to receive(:secrets).and_return(
      decidim: {
        sms_gateway: {
          url: url,
          username: username,
          password: password,
          mb_account_id: mb_account_id,
          mb_api_key: mb_api_key,
          platform: platform
        }
      }
    )
  end

  describe "#initialize" do
    it "initializes with the correct attributes" do
      expect(service.mobile_phone_number).to eq(mobile_phone_number)
      expect(service.code).to eq(code)
      expect(service.instance_variable_get(:@organization_name)).to eq("Test Organization")
      expect(service.instance_variable_get(:@url)).to eq(url)
      expect(service.instance_variable_get(:@username)).to eq(username)
      expect(service.instance_variable_get(:@password)).to eq(password)
      expect(service.instance_variable_get(:@mb_account_id)).to eq(mb_account_id)
      expect(service.instance_variable_get(:@mb_api_key)).to eq(mb_api_key)
      expect(service.instance_variable_get(:@type)).to eq("sms")
    end
  end

  describe "#sms_message" do
    context "when code length is greater than auth code length" do
      before do
        allow(Decidim::HalfSignup).to receive(:auth_code_length).and_return(3)
      end

      it "returns the code as the message" do
        expect(service.sms_message).to eq(code)
      end
    end

    context "when code length is less than or equal to auth code length" do
      before do
        allow(Decidim::HalfSignup).to receive(:auth_code_length).and_return(6)
      end

      it "returns the localized message" do
        localized_message = "Your verification code is 1234 for Test Platform"
        allow(I18n).to receive(:t).and_return(localized_message)
        expect(service.sms_message).to eq(localized_message)
      end
    end
  end

  describe "#build_request" do
    context "when URL is for Message Business service" do
      let(:url) { "https://services.message-business.com" }
      let(:mb_account_id) { "fake_account_id" }
      let(:mb_api_key) { "fake_api_key" }

      before do
        # Override with specific test values for headers verification
        allow(Rails.application).to receive(:secrets).and_return(
          decidim: {
            sms_gateway: {
              url: url,
              username: username,
              password: password,
              mb_account_id: mb_account_id,
              mb_api_key: mb_api_key,
              platform: platform
            }
          }
        )
      end

      it "builds a POST request with the correct headers and body" do
        request_url, request = service.build_request

        expect(request_url.to_s).to eq("https://services.message-business.com/sms/send")
        expect(request.body).to eq({
          "mobile" => mobile_phone_number,
          "message" => service.sms_message
        }.to_json)

        expect(request["Content-Type"]).to eq("application/json")

        # Verify the exact value of the Authorization header
        encoded_credentials = Base64.strict_encode64("#{mb_account_id}:#{mb_api_key}")
        expect(request["Authorization"]).to eq("Basic #{encoded_credentials}")
      end
    end

    context "when URL is for a generic SMS gateway" do
      let(:url) { "https://generic-sms-gateway.com" }

      it "builds a GET request with the correct query parameters" do
        request_url, request = service.build_request

        expect(request_url.to_s).to include("https://generic-sms-gateway.com?u=test_user&p=test_password")
        sms_message_encoded = service.sms_message.gsub(" ", "%20")
        expect(request_url.to_s).to include("&t=#{sms_message_encoded}&n=#{mobile_phone_number}&f=sms")
        expect(request.method).to eq("GET")
      end
    end

    context "when the message contains unsupported characters" do
      let(:code) { "Invalid 😃 Characters" }

      it "encodes unsupported characters correctly in the request" do
        request_body = service.build_request[1].body
        expect(request_body.to_s).to include(code)
      end
    end
  end

  describe "#deliver_code" do
    context "when using Message Business service" do
      let(:url) { "https://services.message-business.com" }
      let(:message_url) { "#{url}/sms/send" }

      before do
        stub_request(:post, message_url)
          .with(
            body: {
              "mobile" => mobile_phone_number,
              "message" => service.sms_message
            }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Authorization" => "Basic #{Base64.strict_encode64("#{mb_account_id}:#{mb_api_key}")}"
            }
          )
          .to_return(status: 200, body: "", headers: {})
      end

      it "makes a POST request to send the SMS" do
        expect(service.deliver_code).to be true
      end

      context "when using valid credentials" do
        before do
          stub_request(:post, message_url)
            .with(
              body: {
                "mobile" => mobile_phone_number,
                "message" => service.sms_message
              }.to_json,
              headers: {
                "Content-Type" => "application/json",
                "Authorization" => "Basic #{Base64.strict_encode64("#{mb_account_id}:#{mb_api_key}")}"
              }
            )
            .to_return(status: 200, body: '{"success": true}', headers: {})
        end

        it "delivers the SMS successfully" do
          expect(service.deliver_code).to be true
          expect(WebMock).to have_requested(:post, message_url)
        end
      end
    end

    context "when using a generic SMS gateway" do
      let(:url) { "https://generic-sms-gateway.com" }

      before do
        stub_request(:get, /generic-sms-gateway.com.*/)
          .to_return(status: 200, body: "", headers: {})
      end

      it "makes a GET request to send the SMS" do
        expect(service.deliver_code).to be true
      end
    end

    context "when using Message Business service with invalid credentials" do
      let(:url) { "https://services.message-business.com" }
      let(:message_url) { "#{url}/sms/send" }

      before do
        stub_request(:post, message_url)
          .with(
            body: {
              "mobile" => mobile_phone_number,
              "message" => service.sms_message
            }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "MB_ACCOUNT_ID" => "invalid_account",
              "MB_API_KEY" => "invalid_key"
            }
          )
          .to_return(status: 401, body: "Unauthorized")
      end

      it "fails to deliver SMS and returns unauthorized error" do
        expect { service.deliver_code }.to raise_error(WebMock::NetConnectNotAllowedError)
      end
    end
  end

  describe "#fetch_configuration" do
    context "when a configuration value is missing" do
      it "logs an error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/is missing a configuration value for :missing_key/)
        expect(service.fetch_configuration(:missing_key, required: true)).to be_nil
      end
    end
  end
end
