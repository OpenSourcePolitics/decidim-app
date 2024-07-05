# frozen_string_literal: true

module OpenIDConnectExtends
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.mounted_helpers

    option :logout_policy, "none"

    def other_phase
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
          return redirect(end_session_uri) if end_session_uri
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
  end
end

OmniAuth::Strategies::OpenIDConnect.class_eval do
  include(OpenIDConnectExtends)
end
