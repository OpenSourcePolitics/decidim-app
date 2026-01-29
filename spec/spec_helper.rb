# frozen_string_literal: true

require "decidim/dev"

Decidim::Dev.dummy_app_path = File.expand_path(Rails.root.to_s)
require "decidim/dev/test/base_spec_helper"

RSpec.configure do |config|
  config.formatter = ENV.fetch("RSPEC_FORMAT", "progress").to_sym

  Capybara.default_max_wait_time = ENV["CI"] ? 10 : 5
  Capybara.disable_animation = true
  Capybara.server = :puma, { Silent: true }

  if ENV["CI"]
    require "redis"
    Redis.new
    Capybara.server_port = 9887 + ENV["TEST_ENV_NUMBER"].to_i
  end

  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new

    options.args << "--headless=new"
    options.args << "--no-sandbox"
    options.args << "--disable-dev-shm-usage"
    options.args << "--disable-search-engine-choice-screen"
    options.args << "--disable-gpu"
    options.args << "--disable-software-rasterizer"
    options.args << "--disable-extensions"
    options.args << "--disable-background-networking"
    options.args << "--disable-default-apps"
    options.args << "--disable-sync"
    options.args << "--disable-translate"
    options.args << "--disable-web-security"
    options.args << "--hide-scrollbars"
    options.args << "--metrics-recording-only"
    options.args << "--mute-audio"
    options.args << "--no-first-run"
    options.args << "--safebrowsing-disable-auto-update"
    options.args << "--disable-blink-features=AutomationControlled"
    options.args << "--force-prefers-reduced-motion"
    options.args << "--user-data-dir=/tmp/decidim_tests_user_data_#{ENV.fetch("TEST_ENV_NUMBER", nil)}_#{rand(1000)}"
    options.args << if ENV["BIG_SCREEN_SIZE"].present?
                      "--window-size=1920,3000"
                    else
                      "--window-size=1920,1080"
                    end
    options.args << "--ignore-certificate-errors" if ENV["TEST_SSL"]

    options.add_preference("intl.accept_languages", "en-GB")
    options.add_preference("download.prompt_for_download", false)
    options.add_preference("download.default_directory", "/tmp")

    options.logging_prefs = { browser: "OFF", driver: "OFF" } if ENV["CI"]

    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      "goog:loggingPrefs" => { browser: "OFF", driver: "OFF", performance: "OFF" }
    )

    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: options,
      capabilities: capabilities,
      timeout: 180
    )
  end

  config.before(:each, type: :system) do
    driven_by :headless_chrome

    Capybara.current_session.server.wait_for_pending_requests if ENV["CI"] && Capybara.current_session.server
  end

  config.after(:each, type: :system) do
    if page.driver.browser.respond_to?(:window_handles)
      page.driver.browser.window_handles[1..-1]&.each do |handle|
        page.driver.browser.switch_to.window(handle)
        page.driver.browser.close
      end
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.first) if page.driver.browser.window_handles.any?
    end
  rescue Selenium::WebDriver::Error::InvalidSessionIdError
    # Session already closed, nothing to do here
  end
end

Rails.application.config.assets.check_precompiled_asset = false if ENV["CI"]
