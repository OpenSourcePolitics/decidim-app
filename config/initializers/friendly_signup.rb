# frozen_string_literal: true

return unless defined?(Decidim::FriendlySignup)

Decidim::FriendlySignup.configure do |config|
  # Override password views or leave the originals (default is true):
  config.override_passwords = ENV.fetch("FRIENDLY_SIGNUP_OVERRIDE_PASSWORDS", "1") == "1"

  # Automatically validate user inputs in the register form (default is true):
  config.use_instant_validation = ENV.fetch("FRIENDLY_SIGNUP_INSTANT_VALIDATION", "1") == "1"

  # Hide nickname field and create one automatically from user's name or email (default is true)
  config.hide_nickname = ENV.fetch("FRIENDLY_SIGNUP_HIDE_NICKNAME", "1") == "1"

  # Send the users a 4-digit number that needs to be entered in a confirmation page instead of a confirmation link (default is true)
  config.use_confirmation_codes = ENV.fetch("FRIENDLY_SIGNUP_USE_CONFIRMATION_CODES", "1") == "1"
end
