# frozen_string_literal: true

require_relative "boot"

require "decidim/rails"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module DecidimApp
  class Application < Rails::Application
    config.load_defaults 7.0

    config.after_initialize do
      require "extends/commands/decidim/proposals/publish_proposal_extends"
      require "extends/commands/decidim/admin/create_attachment_extends"
      require "extends/controllers/decidim/comments/comments_controller_extends"
      require "extends/forms/decidim/comments/comment_form_extends"
    end
  end
end
