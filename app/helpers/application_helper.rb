# frozen_string_literal: true

module ApplicationHelper
  def force_profile_sync_on_omniauth_connection?
    !current_organization.sign_in_enabled? &&
      current_organization.enabled_omniauth_providers.any? &&
      Decidim::Env.new("OMNIAUTH_FORCE_PROFILE_SYNC", false).to_boolean_string == "true"
  end
end
