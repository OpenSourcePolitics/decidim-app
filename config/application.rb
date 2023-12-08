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
      "X-Content-Type-Options" => "nosniff"
    }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.after_initialize do
      require "extends/controllers/decidim/devise/sessions_controller_extends"
      require "extends/controllers/decidim/editor_images_controller_extends"
      require "extends/services/decidim/iframe_disabler_extends"
      require "extends/helpers/decidim/icon_helper_extends"
      require "extends/commands/decidim/initiatives/admin/update_initiative_answer_extends"

      Decidim::GraphiQL::Rails.config.tap do |config|
        config.initial_query = "{\n  deployment {\n    version\n    branch\n    remote\n    upToDate\n    currentCommit\n    latestCommit\n    locallyModified\n  }\n}".html_safe
      end
    end
  end
end
