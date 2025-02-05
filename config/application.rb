# frozen_string_literal: true

require_relative "boot"

require "decidim/rails"
# Add the frameworks used by your app that are not loaded by Decidim.
require "action_cable/engine"
# require "action_mailbox/engine"
# require "action_text/engine"

require "wicked_pdf"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DevelopmentApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.autoloader = :zeitwerk
    config.time_zone = "Europe/Paris" unless Rails.env.test?
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml").to_s]

    # This needs to be set for correct images URLs in emails
    # DON'T FORGET to ALSO set this in `config/initializers/carrierwave.rb`
    config.action_mailer.asset_host = "https://#{Rails.application.secrets[:asset_host]}/" if Rails.application.secrets[:asset_host].present?
    config.backup = config_for(:backup).deep_symbolize_keys

    config.action_dispatch.default_headers = {
      "X-Frame-Options" => "SAMEORIGIN",
      "X-XSS-Protection" => "1; mode=block",
      "X-Content-Type-Options" => "nosniff",
      "X-Download-Options" => "noopen",
      "X-Permitted-Cross-Domain-Policies" => "none",
      "Referrer-Policy" => "strict-origin-when-cross-origin"
    }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.to_prepare do
      require "extends/helpers/decidim/forms/application_helper_extends"
      require "extends/cells/decidim/forms/step_navigation_cell_extends"
    end

    config.after_initialize do
      # Controllers
      require "extends/controllers/decidim/devise/sessions_controller_extends"
      require "extends/controllers/decidim/editor_images_controller_extends"
      require "extends/controllers/decidim/proposals/proposals_controller_extends"
      require "extends/controllers/decidim/newsletters_controller_extends"
      require "extends/controllers/decidim/admin/scopes_controller_extends"
      require "extends/controllers/decidim/scopes_controller_extends"
      require "extends/controllers/decidim/initiatives/committee_requests_controller_extends"
      require "extends/controllers/decidim/comments/comments_controller"
      # Models
      require "extends/models/decidim/budgets/project_extends"
      require "extends/models/decidim/authorization_extends"
      require "extends/models/decidim/decidim_awesome/proposal_extra_field_extends"
      # Services
      require "extends/services/decidim/iframe_disabler_extends"
      # Helpers
      require "extends/helpers/decidim/meetings/directory/application_helper_extends"
      require "extends/helpers/decidim/icon_helper_extends"
      require "extends/helpers/decidim/check_boxes_tree_helper_extends"
      # Forms
      require "extends/forms/decidim/initiatives/initiative_form_extends"
      require "extends/forms/decidim/initiatives/admin/initiative_form_extends"
      require "extends/forms/decidim/comments/comment_form_extends"
      # Commands
      require "extends/commands/decidim/initiatives/admin/update_initiative_answer_extends"
      require "extends/commands/decidim/budgets/admin/import_proposals_to_budgets_extends"
      require "extends/commands/decidim/admin/destroy_participatory_space_private_user_extends"
      require "extends/commands/decidim/admin/create_attachment_extends"
      # Mailers
      require "extends/mailers/decidim/admin_multi_factor/verification_code_mailer"

      Decidim::GraphiQL::Rails.config.tap do |config|
        config.initial_query = "{\n  deployment {\n    version\n    branch\n    remote\n    upToDate\n    currentCommit\n    latestCommit\n    locallyModified\n  }\n}".html_safe
      end
    end

    if ENV.fetch("RAILS_SESSION_STORE", "") == "active_record"
      initializer "session cookie domain", after: "Expire sessions" do
        Rails.application.config.session_store :active_record_store, key: "_decidim_session", expire_after: Decidim.config.expire_session_after
        ActiveRecord::SessionStore::Session.serializer = :hybrid
      end
    end
  end
end
