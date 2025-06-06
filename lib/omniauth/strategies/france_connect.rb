# frozen_string_literal: true

module OmniAuth
  module Strategies
    class FranceConnect < OpenIDConnect
      option :name, :france_connect
      option :discovery, true
      # option :response_type, "code"
      option :client_auth_method, "basic"
      # option :uid_field, "sub"

      info do
        base_info.merge(
          {
            birthdate: extra.dig(:raw_info, :birthdate),
            birthplace: extra.dig(:raw_info, :birthplace),
            birthcountry: extra.dig(:raw_info, :birthcountry)
          }
        )
      end

      def user_info_name
        [user_info.given_name, user_info.preferred_username || user_info.family_name].join(" ")
      end

      def auth_hash
        session["omniauth.end_session_uri"] = end_session_uri
        super
      end

      def end_session_uri
        return unless end_session_endpoint_is_valid?

        end_session_uri = URI(client_options.end_session_endpoint)
        end_session_uri.query = URI.encode_www_form(
          id_token_hint: credentials[:id_token],
          state: new_state,
          post_logout_redirect_uri: options.post_logout_redirect_uri
        )
        end_session_uri.to_s
      end
    end
  end
end
