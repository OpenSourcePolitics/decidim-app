# frozen_string_literal: true

module AccessTokenExtends
  extend ActiveSupport::Concern

  included do
    def userinfo!(params = {})
      response = resource_request do
        get client.userinfo_uri, params
      end

      if response.is_a?(Hash)
        ::OpenIDConnect::ResponseObject::UserInfo.new response.with_indifferent_access
      else
        response
      end
    end

    private

    def resource_request
      res = yield
      case res.status
      when 200
        res.body
      when 400
        raise BadRequest.new("API Access Failed", res)
      when 401
        raise Unauthorized.new("Access Token Invalid or Expired", res)
      when 403
        raise Forbidden.new("Insufficient Scope", res)
      else
        raise HttpError.new(res.status, "Unknown HttpError", res)
      end
    end
  end
end

OpenIDConnect::AccessToken.class_eval do
  include(AccessTokenExtends)
end
