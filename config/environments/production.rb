# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  #

  # Do not fallback to assets pipeline if a precompiled asset is missed.

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.asset_host = ENV["RAILS_ASSET_HOST"] if ENV["RAILS_ASSET_HOST"].present?

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = Decidim::Env.new("STORAGE_PROVIDER", "local").to_s.to_sym

  config.active_storage.service_urls_expire_in = if %w(amazon amazon_instance_profile minio).include?(ENV["STORAGE_PROVIDER"])
                                                   Decidim::Env.new("DECIDIM_SERVICE_URLS_EXPIRES_IN", "1").to_i
                                                 else
                                                   120_000
                                                 end.weeks

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = Decidim::Env.new("DECIDIM_FORCE_SSL", "auto").default_or_present_if_exists.present?

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = %w(debug info warn error fatal).include?(ENV["RAILS_LOG_LEVEL"]) ? ENV["RAILS_LOG_LEVEL"]&.to_sym : :warn

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id, :ip]

  # Use a different cache store in production.
  config.cache_store = :mem_cache_store, ENV.fetch("MEMCACHE_SERVERS", "localhost:11211")

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :sidekiq
  # config.active_job.queue_name_prefix = "decidim_development_app_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = Logger::Formatter.new
  if ENV.fetch("ENABLE_LETTER_OPENER", "0") == "1"
    config.action_mailer.delivery_method = :letter_opener_web
    config.action_mailer.default_url_options = { port: 3000 }
  else
    # Prevent mailer to crash on seeds
    config.action_mailer.raise_delivery_errors = false

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS", "smtp.example.com"),
      port: Decidim::Env.new("SMTP_PORT", 587).to_i,
      authentication: Decidim::Env.new("SMTP_AUTHENTICATION", "plain").to_s,
      user_name: ENV.fetch("SMTP_USERNAME", "example_user"),
      password: ENV.fetch("SMTP_PASSWORD", "example_password"),
      domain: ENV.fetch("SMTP_DOMAIN", "example.com"),
      enable_starttls_auto: Decidim::Env.new("SMTP_STARTTLS_AUTO", true).to_boolean_string,
      openssl_verify_mode: "none"
    }
  end

  config.log_formatter = Logger::Formatter.new

  config.lograge.enabled = true
  config.lograge.ignore_actions = ["HealthCheck::HealthCheckController#index"]
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.custom_options = lambda do |event|
    {
      remote_ip: event.payload[:remote_ip],
      params: event.payload[:params].except("controller", "action", "format", "utf8"),
      user_id: event.payload[:user_id],
      organization_id: event.payload[:organization_id],
      referer: event.payload[:referer]
    }
  end

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.ssl_options = {
    redirect: {
      exclude: ->(request) { /health_check/.match?(request.path) }
    }
  }
end
