# frozen_string_literal: true

module Decidim
  module AccountControllerExtends
    def update
      enforce_permission_to(:update, :user, current_user:)

      @account = form(Decidim::AccountForm).from_params(account_params)

      Decidim::UpdateAccount.call(@account) do
        on(:ok) do |email_is_unconfirmed|
          flash[:notice] = if email_is_unconfirmed
                             t("account.update.success_with_email_confirmation", scope: "decidim")
                           else
                             t("account.update.success", scope: "decidim")
                           end

          bypass_sign_in(current_user)

          redirect_url = session.delete(:euf_redirect_url) || decidim.account_path
          redirect_to redirect_url
        end

        on(:invalid) do |password|
          fetch_entered_password(password)
          flash[:alert] = t("account.update.error", scope: "decidim")
          render action: :show
        end
      end
    end

    def destroy
      enforce_permission_to(:delete, :user, current_user:)
      @form = form(Decidim::DeleteAccountForm).from_params(params)
      Decidim::DestroyAccount.call(@form) do
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
      if active_omniauth_session?
        handle_omniauth_logout
      else
        redirect_to decidim.root_path
      end
    end

    def handle_omniauth_logout
      provider = session.delete("omniauth.provider")
      omniauth_config = DecidimApp::Omniauth::Configurator.new(provider, request.env)
      logout_policy = omniauth_config.options(:logout_policy)
      logout_path = omniauth_config.options(:logout_path)

      if provider.present? && logout_policy == "session.destroy" && logout_path.present?
        redirect_to omniauth_logout_path(provider, logout_path)
      else
        redirect_to decidim.root_path
      end
    end

    def handle_invalid_destruction
      flash[:alert] = t("account.destroy.error", scope: "decidim")
      redirect_to decidim.root_path
    end

    def account_params
      params[:user][:name] = current_user.name if disable_profile_field?(:name)
      params[:user][:email] = current_user.email if disable_profile_field?(:email)
      params[:user][:nickname] ||= current_user.nickname
      params[:user][:tos_agreement] = "1"
      params[:user].to_unsafe_h
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
