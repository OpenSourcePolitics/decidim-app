# frozen_string_literal: true

require "decidim/dev"

Decidim::Dev.dummy_app_path = File.expand_path(Rails.root.to_s)
require "decidim/dev/test/base_spec_helper"

RSpec.configure do |config|
  config.formatter = ENV.fetch("RSPEC_FORMAT", "progress").to_sym

  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.args << "--headless=new"
    options.args << "--no-sandbox"
    options.args << if ENV["BIG_SCREEN_SIZE"].present?
                      "--window-size=1920,3000"
                    else
                      "--window-size=1920,1080"
                    end
    options.args << "--ignore-certificate-errors" if ENV["TEST_SSL"]
    options.add_preference("intl.accept_languages", "en-GB")
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options:
    )
  end
end
