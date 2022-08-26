# frozen_string_literal: true

require 'oauth2'
require 'omniauth'
require 'securerandom'
require 'socket'
require 'timeout'
require 'forwardable'
require 'open-uri'

module OmniAuth
  module Strategies
    class CultuurConnect
      include OmniAuth::Strategy
      include Rails.application.routes.mounted_helpers

      extend Forwardable

      def_delegator :request, :params

      args %i[client_id client_secret site]

      option :name, :cultuur_connect

      option :client_id, nil
      option :client_secret, nil
      option :site, nil
      option :client_options,
             authorize_url: '/idp/rest/auth',
             token_url: '/idp/rest/auth/token',
             logout_url: '/idp/rest/auth/logout'
      option :issuer, nil
      option :authorize_params, {}
      option :authorize_options, %i[scope state]
      option :token_params, {}
      option :token_options, []
      option :auth_token_params, {}
      option :provider_ignores_state, true # omniauth-oauth2 default was : false

      option :redirect_url, nil

      attr_accessor :access_token

      def client
        options.client_options[:site] = options.site
        ::OAuth2::Client.new(options.client_id, options.client_secret, deep_symbolize(options.client_options))
      end

      credentials do
        {}
      end

      def request_phase
        redirect client.auth_code.authorize_url({ redirect_uri: callback_url }.merge(authorize_params))
      end

      def authorize_params
        options.authorize_params[:state] = SecureRandom.hex(24)
        params = options.authorize_params.merge(options_for('authorize'))
        if OmniAuth.config.test_mode
          @env ||= {}
          @env['rack.session'] ||= {}
        end
        session['omniauth.state'] = params[:state]
        params
      end

      def token_params
        options.token_params.merge(options_for('token'))
      end

      def callback_phase # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity
        error = request.params['error_reason'] || request.params['error']
        if error
          fail!(error, CallbackError.new(request.params['error'], request.params['error_description'] || request.params['error_reason'], request.params['error_uri']))
        elsif !options.provider_ignores_state && (request.params['state'].to_s.empty? || request.params['state'] != session.delete('omniauth.state'))
          fail!(:csrf_detected, CallbackError.new(:csrf_detected, 'CSRF detected'))
        else
          self.access_token = build_access_token
          # self.access_token = access_token.refresh! if access_token.expired?
          super
        end
      rescue ::OAuth2::Error, CallbackError => e
        fail!(:invalid_credentials, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        fail!(:timeout, e)
      rescue ::SocketError => e
        fail!(:failed_to_connect, e)
      end

      def other_phase
        if logout_path_pattern.match?(current_path)
          setup_phase
          return redirect(end_session_uri) if end_session_uri
        end
        call_app!
      end

      def end_session_uri
        end_session_uri = URI(options.site + options.client_options.logout_url)
        end_session_uri.query = encoded_post_logout_redirect_uri
        end_session_uri.to_s
      end

      uid do
        raw_info.dig('sub')
      end

      info do
        Rails.logger.debug raw_info.inspect
        {
          name: find_name,
          email: raw_info.dig('email'),
          nickname: find_nickname,
          firstname: raw_info.dig('firstname'),
          surname: raw_info.dig('surname')
        }
      end

      def raw_info
        @raw_info ||= access_token
      end

      def find_name
        "#{raw_info.dig('firstname')} #{raw_info.dig('surname')} #{raw_info.dig('familyname')}".strip
      end

      def find_nickname
        ::Decidim::UserBaseEntity.nicknamize(find_name)
      end

      def on_auth_path?
        on_request_path? || on_callback_path? || on_path?(logout_path)
      end

      protected

      def build_access_token
        verifier = request.params['code']
        @build_access_token ||= client.auth_code.get_token(verifier, { redirect_uri: callback_url }.merge(token_params.to_hash(symbolize_keys: true)), deep_symbolize(options.auth_token_params))
      rescue ::OAuth2::Error => e
        if e.try(:response).try(:parsed)
          @build_access_token ||= (::JWT.decode e.response.parsed['idToken'], nil, false)[0]
        else
          raise e
        end
      end

      def deep_symbolize(options)
        hash = {}
        options.each do |key, value|
          hash[key.to_sym] = value.is_a?(Hash) ? deep_symbolize(value) : value
        end
        hash
      end

      def options_for(option)
        hash = {}
        options.send(:"#{option}_options").select { |key| options[key] }.each do |key|
          hash[key.to_sym] = if options[key].respond_to?(:call)
                               options[key].call(env)
                             else
                               options[key]
          end
        end
        hash
      end

      def callback_url
        options.redirect_url || (full_host + script_name + callback_path)
      end

      def encoded_post_logout_redirect_uri
        URI.encode_www_form(
          redirect: (full_host + logout_path + '/callback')
        )
      end

      def logout_path
        "#{path_prefix}/#{name}/logout"
      end

      def logout_path_pattern
        @logout_path_pattern ||= %r{\A#{Regexp.quote(request_path)}(/logout)([^/]*)$}
      end

      # An error that is indicated in the OAuth 2.0 callback.
      # This could be a `redirect_uri_mismatch` or other
      class CallbackError < StandardError
        attr_accessor :error, :error_reason, :error_uri

        def initialize(error, error_reason = nil, error_uri = nil)
          self.error = error
          self.error_reason = error_reason
          self.error_uri = error_uri
        end

        def message
          [error, error_reason, error_uri].compact.join(' | ')
        end
      end
    end
  end
end
