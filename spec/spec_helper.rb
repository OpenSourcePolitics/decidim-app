# frozen_string_literal: true

require "decidim/dev"
Decidim::Dev.dummy_app_path = File.expand_path(Rails.root.to_s)
require "decidim/dev/test/base_spec_helper"

Dir.glob("./spec/support/**/*.rb").each { |f| require f }

RSpec.configure do |config|
  config.formatter = ENV.fetch("RSPEC_FORMAT", "progress").to_sym
  config.include EnvironmentVariablesHelper
  config.include SkipIfUndefinedHelper

  config.before do
    # Initializers configs
    SocialShareButton.configure do |social_share_button|
      social_share_button.allow_sites = %w(twitter facebook whatsapp_app whatsapp_web telegram)
    end
  end
end
