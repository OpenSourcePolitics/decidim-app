# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
#
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV", "development")

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
# preload_app!

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Development SSL
if ENV.fetch("DEV_SSL", nil) && defined?(Bundler) && (dev_gem = Bundler.load.specs.find { |spec| spec.name == "decidim-dev" })
  cert_dir = ENV.fetch("DEV_SSL_DIR") { "#{dev_gem.full_gem_path}/lib/decidim/dev/assets" }
  ssl_bind(
    "0.0.0.0",
    ENV.fetch("DEV_SSL_PORT", 3443),
    cert_pem: File.read("#{cert_dir}/ssl-cert.pem"),
    key_pem: File.read("#{cert_dir}/ssl-key.pem")
  )
end

if Rails.application.secrets.puma[:health_check][:enabled]
  activate_control_app "tcp://0.0.0.0:#{Rails.application.secrets.puma[:health_check][:port]}", { auth_token: Rails.application.secrets.puma[:health_check][:token] }
end
