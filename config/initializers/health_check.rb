# frozen_string_literal: true

return unless Rails.env.production?

HealthCheck.setup do |config|
  # uri prefix (no leading slash)
  config.uri = "health_check"

  # Text output upon success
  config.success = "success"

  # Text output upon failure
  config.failure = "health_check failed"

  # Disable the error message to prevent /health_check from leaking
  # sensitive information
  config.include_error_in_response_body = false

  # Log level (success or failure message with error details is sent to rails log unless this is set to nil)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "warn").to_sym

  # Timeout in seconds used when checking smtp server
  config.smtp_timeout = 30.0

  config.http_status_for_error_object = 500

  # You can customize which checks happen on a standard health check, eg to set an explicit list use:
  config.standard_checks = %w(migrations)
end
