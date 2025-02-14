# frozen_string_literal: true

require_relative "boot"

require "decidim/rails"
require "action_cable/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module DecidimApp
  class Application < Rails::Application
    config.load_defaults 6.1

    config.after_initialize do
      require "extends/commands/decidim/proposals/publish_proposal_extends"
    end
  end
end
