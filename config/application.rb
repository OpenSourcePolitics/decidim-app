# frozen_string_literal: true

require_relative "boot"

require "decidim/rails"
require "action_cable/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module DecidimApp
  class Application < Rails::Application
    config.load_defaults 6.1

    config.after_initialize do # run after the initialization of the framework itself, engines, and all the application's initializers in config/initializers
      require "extends/controllers/decidim/comments/comments_controller_extends"
      require "extends/forms/decidim/comments/comment_form_extends"
    end
  end
end
