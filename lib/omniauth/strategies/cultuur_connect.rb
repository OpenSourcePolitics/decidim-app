# frozen_string_literal: true

require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class CultuurConnect < OmniAuth::Strategies::OAuth2
      option :name, :cultuur_connect
      option :client_options, {
        authorize_url: "/idp/rest/auth",
        token_url: "/idp/rest/auth/token",
        logout_url: "/idp/rest/auth/logout"
      }
      option :provider_ignores_state, true

      uid { raw_info["sub"] }

      info do
        Rails.logger.debug raw_info.inspect
        {
          name: find_name,
          email: raw_info["email"],
          nickname: find_nickname,
          firstname: raw_info["firstname"],
          surname: raw_info["surname"]
        }
      end

      extra { { "raw_info" => raw_info } }

      def raw_info
        @raw_info ||= ::JWT.decode(access_token.token, nil, false)[0]
      end

      def find_name
        [raw_info["firstname"], raw_info["surname"], raw_info["familyname"]].compact.join(" ").strip
      end

      def find_nickname
        ::Decidim::UserBaseEntity.nicknamize(find_name)
      end

      protected

      def build_access_token
        @build_access_token ||= client.auth_code.get_token(
          request.params["code"],
          { redirect_uri: callback_url, client_id: options.client_id, client_secret: options.client_secret }
            .merge(token_params.to_hash(symbolize_keys: true)),
          deep_symbolize(options.auth_token_params)
        )
      rescue ::OAuth2::Error => e
        handle_token_error(e)
      end

      private

      def handle_token_error(error)
        raise error unless error.try(:response)&.parsed

        @handle_token_error ||= (::JWT.decode error.response.parsed["idToken"], nil, false)[0]
      end
    end
  end
end
