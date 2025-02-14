# frozen_string_literal: true

require_relative "boot"

require "decidim/rails"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module DecidimApp
  class Application < Rails::Application
    config.load_defaults 7.0

    config.action_dispatch.cookies_serializer = :hybrid
    config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1
  end
end
