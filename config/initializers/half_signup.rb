# frozen_string_literal: true

Decidim::HalfSignup.configure do |config|
  config.show_tos_page_after_signup = Rails.application.secrets.dig(:decidim, :half_signup, :show_tos_page_after_signup)
  config.auth_code_length = 4
  config.default_countries = ENV.fetch("AVAILABLE_LOCALES", "fr").split(",").map(&:to_sym)

  config.skip_csrf = ENV.fetch("HALF_SIGNUP_SKIP_CSRF", "false") == "true"
end
