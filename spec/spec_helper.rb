# frozen_string_literal: true

require "decidim/dev"
Decidim::Dev.dummy_app_path = File.expand_path(Rails.root.to_s)
require "decidim/dev/test/base_spec_helper"

Dir.glob("./spec/support/**/*.rb").each { |f| require f }

Capybara.register_driver :headless_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.args << "--headless=new"
  options.args << "--no-sandbox"
  options.args << if ENV["BIG_SCREEN_SIZE"].present?
                    "--window-size=1920,3000"
                  else
                    "--window-size=1920,1080"
                  end
  options.args << "--ignore-certificate-errors" if ENV["TEST_SSL"]
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    capabilities: [options]
  )
end

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

def bundler_gem_path(gem_name)
  spec = Bundler.rubygems.find_name(gem_name).first
  spec.full_gem_path
rescue Gem::LoadError
  nil
end

def fixture_asset(name)
  fixture_path = bundler_gem_path("decidim-budgets_importer")
  return "" if fixture_path.blank?

  File.expand_path(File.join(fixture_path, "spec", "fixtures", "files", name))
end

# Public: Returns a file for testing, just like file fields expect it
def fixture_test_file(filename, content_type)
  Rack::Test::UploadedFile.new(fixture_asset(filename), content_type)
end
