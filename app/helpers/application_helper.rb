# frozen_string_literal: true

module ApplicationHelper
  def force_profile_sync_on_omniauth_connection?
    !current_organization.sign_in_enabled? &&
      current_organization.enabled_omniauth_providers.any? &&
      Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync)
  end
end
