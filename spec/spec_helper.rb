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
    options.args << "--disable-search-engine-choice-screen"
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

  # Recent Chrome versions no longer know the "iPhone 6" device preset used by
  # decidim-dev, so the same device is emulated from its explicit metrics.
  Capybara.register_driver :iphone do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.args << "--headless=new"
    options.args << "--no-sandbox"
    options.args << "--disable-dev-shm-usage"
    options.add_emulation(
      device_metrics: { width: 375, height: 667, pixelRatio: 2, touch: true, mobile: true },
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
    )
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options:
    )
  end
end
