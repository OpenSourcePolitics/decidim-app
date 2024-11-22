# frozen_string_literal: true

require "uri"
require "net/http"

module Decidim
  class SmsGatewayService
    attr_reader :mobile_phone_number, :code

    def initialize(mobile_phone_number, code, sms_gateway_context = {})
      Rails.logger.debug { "#{mobile_phone_number} - #{code}" }

      @mobile_phone_number = mobile_phone_number
      @code = code
      @organization_name = sms_gateway_context[:organization]&.name
      @url = fetch_configuration(:url)
      @username = fetch_configuration(:username)
      @password = fetch_configuration(:password)
      @message = sms_message
      @type = "sms"
    end

    def deliver_code
      url = URI("#{@url}?u=#{@username}&p=#{@password}&t=#{@message}&n=#{@mobile_phone_number}&f=#{@type}")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Get.new(url)
      https.request(request)

      true
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
