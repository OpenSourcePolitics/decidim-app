# frozen_string_literal: true

module SessionControllerExtends
  extend ActiveSupport::Concern

  included do
    include Decidim::AfterSignInActionHelper

    def destroy
      if active_omniauth_session?
        provider = session.delete("omniauth.provider")
        omniauth_config = DecidimApp::Omniauth::Configurator.new(provider, request.env)
        logout_policy = omniauth_config.options(:logout_policy)
        logout_path = omniauth_config.options(:logout_path)
      end

      if provider.present? && logout_policy == "session.destroy" && logout_path.present?
        redirect_to omniauth_logout_path(provider, logout_path)
      else
        if current_user
          current_user.invalidate_all_sessions!
          request.params[stored_location_key_for(current_user)] = stored_location_for(current_user) if pending_redirect?(current_user)
        end

        if params[:translation_suffix].present?
          super { set_flash_message! :notice, params[:translation_suffix], { scope: "decidim.devise.sessions" } }
        else
          super
        end
      end
    end

    def after_sign_in_path_for(user)
      after_sign_in_action_for(user, request.params[:after_action]) if request.params[:after_action].present?

      if user.present? && user.blocked?
        check_user_block_status(user)
      elsif !skip_first_login_authorization? && (first_login_and_not_authorized?(user) && !user.admin? && !pending_redirect?(user))
        decidim_verifications.first_login_authorizations_path
      else
        super
      end
    end

    def after_sign_out_path_for(user)
      request.params[stored_location_key_for(user)] || request.referer || super
    end

    private

    # Skip authorization handler by default
    def skip_first_login_authorization?
      ActiveRecord::Type::Boolean.new.cast(ENV.fetch("SKIP_FIRST_LOGIN_AUTHORIZATION", "false"))
    end
  end

  def active_omniauth_session?
    session["omniauth.provider"].present?
  end

  def omniauth_logout_path(provider, logout_path)
    uri = URI.parse(decidim.send("user_#{provider}_omniauth_authorize_path"))
    uri.path += logout_path
    uri.to_s
  end
end

Decidim::Devise::SessionsController.class_eval do
  include(SessionControllerExtends)
end
