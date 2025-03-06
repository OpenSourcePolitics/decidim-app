# frozen_string_literal: true

require "uri"
require "net/http"

module Decidim
  class SmsGatewayService
    attr_reader :mobile_phone_number, :code

    def initialize(mobile_phone_number, code, sms_gateway_context = {})
      @mobile_phone_number = mobile_phone_number
      @code = code
      @organization_name = sms_gateway_context[:organization]&.name
      @url = fetch_configuration(:url)
      @username = fetch_configuration(:username, required: false)
      @password = fetch_configuration(:password, required: false)
      @mb_account_id = fetch_configuration(:mb_account_id, required: false)
      @mb_api_key = fetch_configuration(:mb_api_key, required: false)
      @message = sms_message
      @type = "sms"
    end

    def deliver_code
      url, request = build_request
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      https.request(request)
      true
    end

    def build_request
      if @url.include?("services.message-business.com")
        url = URI("#{@url}/sms/send")
        request = Net::HTTP::Post.new(url)

        request["Content-Type"] = "application/json"
        request["Authorization"] = "Basic #{Base64.strict_encode64("#{@mb_account_id}:#{@mb_api_key}")}"

        body = {
          "mobile" => @mobile_phone_number,
          "message" => @message
        }
        body["oadc"] = fetch_configuration(:oadc, required: false) if fetch_configuration(:oadc, required: false).present?
        request.body = JSON.dump(body)
      else
        url = URI("#{@url}?u=#{@username}&p=#{@password}&t=#{@message}&n=#{@mobile_phone_number}&f=#{@type}")
        request = Net::HTTP::Get.new(url)
      end

      [url, request]
    end

    # Ensure '@code' is not a full i18n keys rather than a verification code.
    def sms_message
      return code if code.to_s.length > Decidim::HalfSignup.auth_code_length

      platform = fetch_configuration(:platform, required: false).presence || @organization_name
      I18n.t("sms_verification_workflow.message", code: code, platform: platform)
    end

    def fetch_configuration(key, required: true)
      value = Rails.application.secrets.dig(:decidim, :sms_gateway, key.to_sym)
      if required && value.blank?
        Rails.logger.error "Decidim::SmsGatewayService is missing a configuration value for :#{key}, " \
                           "please check Rails.application.secrets.dig(:decidim, :sms_gateway, :#{key}) " \
                           "or environment variable SMS_GATEWAY_#{key.to_s.upcase}"
      end
      value
    end
  end
end
