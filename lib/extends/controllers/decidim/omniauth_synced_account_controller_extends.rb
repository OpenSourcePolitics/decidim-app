# frozen_string_literal: true

require "active_support/concern"
module OmniauthSyncedAccountControllerExtends
  extend ActiveSupport::Concern

  included do
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
  end
end

Decidim::AccountController.include(OmniauthSyncedAccountControllerExtends)
