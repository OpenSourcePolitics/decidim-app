# frozen_string_literal: true

require "active_support/concern"
module AccountControllerExtends
  extend ActiveSupport::Concern

  included do
    def destroy
      enforce_permission_to :delete, :user, current_user: current_user
      @form = form(Decidim::DeleteAccountForm).from_params(params)

      Decidim::DestroyAccount.call(current_user, @form) do
        on(:ok) do
          sign_out(current_user)
          flash[:notice] = t("account.destroy.success", scope: "decidim")
          if active_omniauth_session?
            provider = session.delete("omniauth.provider")
            logout_policy = session.delete("omniauth.#{provider}.logout_policy")
            logout_path = session.delete("omniauth.#{provider}.logout_path")
          end

          if provider.present? && logout_policy == "session.destroy" && logout_path.present?
            redirect_to omniauth_logout_path(provider, logout_path)
          elsif active_france_connect_session?
            destroy_france_connect_session(session["omniauth.france_connect.end_session_uri"])
          end
        end

        on(:invalid) do
          flash[:alert] = t("account.destroy.error", scope: "decidim")
          redirect_to decidim.root_path
        end
      end
    end

    private

    def force_profile_sync_on_omniauth_connection?
      !current_organization.sign_in_enabled? &&
        current_organization.enabled_omniauth_providers.any? &&
        Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync_on_omniauth_connection)
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

Decidim::AccountController.include(AccountControllerExtends)
