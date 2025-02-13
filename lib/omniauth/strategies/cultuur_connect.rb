# frozen_string_literal: true

require "oauth2"
require "omniauth"
require "securerandom"
require "socket"
require "timeout"
require "forwardable"
require "open-uri"

module OmniAuth
  module Strategies
    class CultuurConnect
      include OmniAuth::Strategy

      extend Forwardable
      def_delegator :request, :params

      args [:client_id, :client_secret, :site]
      option :name, :cultuur_connect
      option :client_id, nil
      option :client_secret, nil
      option :site, nil
      option :issuer, nil
      option :redirect_url, nil
      option :provider_ignores_state, true

      option :client_options, {
        authorize_url: "/idp/rest/auth",
        token_url: "/idp/rest/auth/token",
        logout_url: "/idp/rest/auth/logout"
      }

      option :authorize_params, {}
      option :authorize_options, [:scope, :state]
      option :token_params, {}
      option :token_options, []
      option :auth_token_params, {}

      attr_accessor :access_token

      def client
        options.client_options[:site] = options.site
        @client ||= ::OAuth2::Client.new(
          options.client_id,
          options.client_secret,
          deep_symbolize(options.client_options)
        )
      end

      credentials { {} }

      def request_phase
        redirect client.auth_code.authorize_url({ redirect_uri: callback_url }.merge(authorize_params))
      end

      def authorize_params
        options.authorize_params[:state] = SecureRandom.hex(24)
        params = options.authorize_params.merge(options_for(:authorize))
        session["omniauth.state"] = params[:state] if OmniAuth.config.test_mode
        params
      end

      def token_params
        options.token_params.merge(options_for(:token))
      end

      def callback_phase
        if csrf_detected? || request.params["error"]
          handle_callback_error
        else
          self.access_token = build_access_token
          super
        end
      rescue ::OAuth2::Error, CallbackError => e
        fail!(:invalid_credentials, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT, ::SocketError => e
        fail!(:failed_to_connect, e)
      end

      def other_phase
        return redirect(end_session_uri) if logout_path_pattern.match?(current_path) && end_session_uri

        call_app!
      end

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

      def csrf_detected?
        !options.provider_ignores_state &&
          (request.params["state"].to_s.empty? || request.params["state"] != session.delete("omniauth.state"))
      end

      def handle_callback_error
        error = request.params["error"]

        fail!(error, CallbackError.new(error, request.params["error_description"], request.params["error_uri"]))
      end

      def handle_token_error(error)
        raise error unless error.try(:response)&.parsed

        @handle_token_error ||= (::JWT.decode error.response.parsed["idToken"], nil, false)[0]
      end

      def deep_symbolize(options)
        options.transform_keys(&:to_sym).transform_values do |value|
          value.is_a?(Hash) ? deep_symbolize(value) : value
        end
      end

      def options_for(option)
        options.send(:"#{option}_options").each_with_object({}) do |key, hash|
          hash[key.to_sym] = options[key].respond_to?(:call) ? options[key].call(env) : options[key] if options[key]
        end
      end

      def callback_url
        options.redirect_url || (full_host + script_name + callback_path)
      end

      def end_session_uri
        uri = URI.join(options.site, options.client_options[:logout_url])
        uri.query = URI.encode_www_form(redirect: "#{full_host}#{logout_path}/callback")
        uri.to_s
      end

      def logout_path
        "#{path_prefix}/#{name}/logout"
      end

      def logout_path_pattern
        @logout_path_pattern ||= %r{\A#{Regexp.quote(request_path)}(/logout)([^/]*)$}
      end

      class CallbackError < StandardError
        attr_accessor :error, :error_reason, :error_uri

        def initialize(error, error_reason = nil, error_uri = nil)
          @error = error
          @error_reason = error_reason
          @error_uri = error_uri
        end

        def message
          [error, error_reason, error_uri].compact.join(" | ")
        end
      end
    end
  end
end
