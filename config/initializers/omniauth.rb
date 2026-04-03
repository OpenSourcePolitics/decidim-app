# frozen_string_literal: true

ActiveSupport::Notifications.subscribe "decidim.user.omniauth_registration" do |_name, data|
  Rails.logger.debug "decidim.user.omniauth_registration event in config/initializers/omniauth.rb"

  if Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync)
    Rails.logger.debug "decidim.user.omniauth_registration :: force_profile_sync is enabled"
    Rails.logger.debug { "decidim.user.omniauth_registration :: force_profile_sync fields: #{Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync_fields)}" }
    update_user_profile(data)
  end
end

def update_user_profile(data)
  user = Decidim::User.find(data[:user_id])

  fields = Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync_fields) || []

  if fields.include?("email") && data[:email].present?
    user.email = data[:email]
    user.skip_reconfirmation! if user.email_changed?
  end
  user.name = data[:name] if fields.include?("name") && data[:name].present?

  user.save!(validate: false, touch: false)
end
