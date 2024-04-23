# frozen_string_literal: true

require "uri"
require "net/http"

module Decidim
  class SmsGatewayService
    attr_reader :mobile_phone_number, :code

    def initialize(mobile_phone_number, code, sms_gateway_context)
      @mobile_phone_number = mobile_phone_number
      @code = code
      @organization_name = sms_gateway_context[:organization]&.name
      @url = ENV.fetch("SMS_GATEWAY_URL", nil)
      @username = ENV.fetch("SMS_GATEWAY_USERNAME", nil)
      @password = ENV.fetch("SMS_GATEWAY_PASSWORD", nil)
      @message = I18n.t("sms_verification_workflow.message", code: code, platform: ENV.fetch("SMS_GATEWAY_PLATFORM", @organization_name ))
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
  end
end
