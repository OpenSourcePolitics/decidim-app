if Rails.application.secrets.sentry.enabled?
  Raven.configure do |config|
    config.dsn = Rails.application.secrets.sentry.dsn
  end
end
