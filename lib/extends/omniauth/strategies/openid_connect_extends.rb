# frozen_string_literal: true

module OpenIDConnectExtends
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.mounted_helpers

    option :logout_policy, "none"

    info do
      base_info
    end

    def base_info
      {
        name: user_info_name,
        email: user_info.email,
        email_verified: user_info.email_verified,
        nickname: user_info.preferred_username,
        first_name: user_info.given_name,
        last_name: user_info.family_name,
        gender: user_info.gender,
        image: user_info.picture,
        phone: user_info.phone_number,
        urls: { website: user_info.website }
      }
    end

    def user_info_name
      user_info.name || [user_info.given_name, user_info.family_name].join(" ")
    end

    def other_phase
      log :debug, "logout_path_pattern #{logout_path_pattern}"
      log :debug, "current_path #{current_path}"
      log :debug, "logout_path_pattern match #{logout_path_pattern.match?(current_path)}"
      if logout_path_pattern.match?(current_path)
        if end_session_callback?
          log :debug, "Logout phase callback."
          session.delete("omniauth.logout.callback")
          return redirect(decidim.destroy_user_session_path)
        else
          log :debug, "Logout phase initiated."
          @env["omniauth.strategy"] ||= self
          setup_phase
          options.issuer = issuer if options.issuer.to_s.empty?
          discover!
          session["omniauth.logout.callback"] = end_session_callback_value
          end_session_redirect_uri = end_session_uri
          log :debug, "End session redirect URI: #{end_session_redirect_uri}"
          return redirect(end_session_redirect_uri) if end_session_redirect_uri.present?
        end
      end
      call_app!
    end

    def end_session_uri
      return unless end_session_endpoint_is_valid?

      end_session_uri = URI(client_options.end_session_endpoint)
      end_session_uri.query = URI.encode_www_form(
        id_token_hint: credentials[:id_token],
        post_logout_redirect_uri: options.post_logout_redirect_uri
      )
      end_session_uri.to_s
    end

    def end_session_callback?
      session["omniauth.logout.callback"] == end_session_callback_value
    end

    def end_session_callback_value
      "#{name}--#{session["session_id"]}"
    end

    def user_info
      return @user_info if @user_info

      if access_token.id_token
        decoded = decode_id_token(access_token.id_token).raw_attributes

        response = access_token.userinfo!
        response = decode_id_token(response) if response.is_a?(String)

        log :debug, "Userinfo response: #{response.raw_attributes.to_h}"

        @user_info = ::OpenIDConnect::ResponseObject::UserInfo.new response.raw_attributes.merge(decoded).deep_symbolize_keys
      else
        @user_info = access_token.userinfo!
      end
    end
  end
end

OmniAuth::Strategies::OpenIDConnect.class_eval do
  include(OpenIDConnectExtends)
end
