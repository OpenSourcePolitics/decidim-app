# frozen_string_literal: true

require_relative "boot"

require "decidim/rails"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module DecidimApp
  class Application < Rails::Application
    config.load_defaults 7.0

    config.after_initialize do
      # commands
      require "extends/commands/decidim/proposals/publish_proposal_extends"
      require "extends/commands/decidim/admin/create_attachment_extends"
      require "extends/commands/decidim/assemblies/admin/copy_assembly_extends"
      require "extends/commands/decidim/participatory_processes/admin/copy_participatory_process_extends"
      # forms
      require "extends/forms/decidim/assemblies/admin/assembly_copy_form_extends"
      require "extends/forms/decidim/participatory_processes/admin/participatory_process_copy_form_extends"
      require "extends/forms/decidim/proposals/proposal_form_extends"
      require "extends/forms/decidim/comments/comment_form_extends"
      # controllers
      require "extends/controllers/decidim/admin/scopes_controller_extends"
      require "extends/controllers/decidim/scopes_controller_extends"
      require "extends/controllers/decidim/comments/comments_controller_extends"
      require "extends/controllers/decidim/account_controller_extends"
      require "extends/controllers/decidim/devise_controllers_extends"
      require "extends/controllers/decidim/devise/sessions_controller_extends"
      require "extends/controllers/decidim/devise/omniauth_registrations_controller_extends"
      # helpers
      require "extends/helpers/decidim/check_boxes_tree_helper_extends"
    end
  end
end
