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
      # extends
      require "extends/controllers/decidim/admin/scopes_controller_extends"
      require "extends/controllers/decidim/scopes_controller_extends"
      require "extends/helpers/decidim/check_boxes_tree_helper_extends"
    end
  end
end
