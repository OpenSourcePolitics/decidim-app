# frozen_string_literal: true

module Decidim
  module AccountControllerExtends
    def destroy
      enforce_permission_to :delete, :user, current_user: current_user
      @form = form(Decidim::DeleteAccountForm).from_params(params)
      Decidim::DestroyAccount.call(current_user, @form) do
        on(:ok) do
          handle_successful_destruction
        end
        on(:invalid) do
          handle_invalid_destruction
        end
      end
    end

    private

    def handle_successful_destruction
      sign_out(current_user)
      flash[:notice] = t("account.destroy.success", scope: "decidim")
      handle_omniauth_logout if active_omniauth_session?

      handle_france_connect_logout if active_france_connect_session?
    end

    def handle_omniauth_logout
      provider = session.delete("omniauth.provider")
      logout_policy = session.delete("omniauth.#{provider}.logout_policy")
      logout_path = session.delete("omniauth.#{provider}.logout_path")

      redirect_to omniauth_logout_path(provider, logout_path) if provider.present? && logout_policy == "session.destroy" && logout_path.present?
    end

    def handle_france_connect_logout
      destroy_france_connect_session(session["omniauth.france_connect.end_session_uri"])
    end

    def handle_invalid_destruction
      flash[:alert] = t("account.destroy.error", scope: "decidim")
      redirect_to decidim.root_path
    end

    def account_params
      if force_profile_sync_on_omniauth_connection?
        params[:user][:name] = current_user.name
        params[:user][:email] = current_user.email
        params[:user][:nickname] = current_user.nickname
      end
      params[:user].to_unsafe_h
    end

    def destroy_france_connect_session(fc_logout_path)
      session.delete("omniauth.france_connect.end_session_uri")
      redirect_to fc_logout_path
    end

    def active_france_connect_session?
      current_organization.enabled_omniauth_providers.include?(:france_connect) && session["omniauth.france_connect.end_session_uri"].present?
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
end

Decidim::AccountController.class_eval do
  prepend(Decidim::AccountControllerExtends)
  include ApplicationHelper
end
