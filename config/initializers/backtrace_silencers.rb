# frozen_string_literal: true

# OmniAuth strategies are Rack middlewares wrapping the whole application, so the
# OpenID Connect `other_phase` override is on the stack of every request. Being the
# only frame under `lib/`, it would be logged as the whole backtrace of any error
# raised further down (e.g. ActionController::InvalidAuthenticityToken).
# Silencing it lets Rails fall back to the full framework trace instead.
Rails.backtrace_cleaner.add_silencer do |line|
  line.match?(%r{\Alib/extends/omniauth/strategies/openid_connect_extends\.rb:\d+:in [`'](?:[\w:]+#)?other_phase'})
end
