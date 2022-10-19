# frozen_string_literal: true

Decidim::FriendlySignup.configure do |config|
  # Override password views or leave the originals (default is true):
  config.override_passwords = true

  # Automatically validate user inputs in the register form (default is true):
  config.use_instant_validation = true

  # Hide nickname field and create one automatically from user's name or email (default is true)
  config.hide_nickname = true

  # Send the users a 4-digit number that needs to be entered in a confirmation page instead of a confirmation link (default is true)
  config.use_confirmation_codes = true
end
