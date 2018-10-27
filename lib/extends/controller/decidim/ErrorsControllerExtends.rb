module ErrorsControllerExtends
  def internal_server_error
    @sentry_event_id = Raven.last_event_id
    @sentry_dsn = unless ENV['SENTRY_DSN'].nil? then ENV['SENTRY_DSN'].gsub(/^https:\/\/([^:]+):[^@]+(.*)/, 'https://\1\2') end
     render(
      status: 500,
    )
  end
end

Decidim::ErrorsController.class_eval do
  prepend(ErrorsControllerExtends)
end
