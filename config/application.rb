# frozen_string_literal: true

require_relative "boot"

require "decidim/rails"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module DecidimApp
  class Application < Rails::Application
    config.load_defaults 7.0

    config.after_initialize do
      require "extends/forms/decidim/proposals/proposal_form_extends"
      require "extends/commands/decidim/proposals/publish_proposal_extends"
      require "extends/commands/decidim/admin/create_attachment_extends"
    end
  end
end
