# frozen_string_literal: true

ActiveSupport::Notifications.subscribe "decidim.user.omniauth_registration" do |_name, data|
  Rails.logger.debug "decidim.user.omniauth_registration event in config/initializers/omniauth.rb"

  next unless Rails.application.secrets.dig(:decidim, :omniauth, :force_profile_sync_on_omniauth_connection)

  Rails.logger.debug "decidim.user.omniauth_registration :: force_profile_sync_on_omniauth_connection is enabled"

  update_user_profile(data)
end

def update_user_profile(data)
  user = Decidim::User.find(data[:user_id])

  user.email = data[:email] if data[:email].present?
  user.name = data[:name] if data[:name].present?
  user.nickname = data[:nickname] if data[:nickname].present? && data.dig(:raw_data, :info, "nickname") != user.nickname

  user.save!(validate: false, touch: false)
end
