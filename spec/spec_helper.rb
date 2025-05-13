# frozen_string_literal: true

require "decidim/dev"
require "fileutils"

Decidim::Dev.dummy_app_path = File.expand_path(Rails.root.to_s)
require "decidim/dev/test/base_spec_helper"

RSpec.configure do |config|
  config.formatter = ENV.fetch("RSPEC_FORMAT", "progress").to_sym

  config.after(:each, type: :system) do
    if defined?(@chrome_tmp_dir) && Dir.exist?(@chrome_tmp_dir)
      FileUtils.rm_rf(@chrome_tmp_dir) rescue nil
    end
  end

  Capybara.server = :puma, { Silent: true }

  Capybara.register_driver :headless_chrome do |app|
    @chrome_tmp_dir = File.join(Dir.tmpdir, "chrome_tmp_#{Process.pid}_#{Time.now.to_i}_#{rand(1000)}")
    FileUtils.mkdir_p(@chrome_tmp_dir)

    options = Selenium::WebDriver::Chrome::Options.new
    options.args << "--headless=new"
    options.args << "--no-sandbox"
    options.args << "--disable-gpu"
    options.args << "--disable-dev-shm-usage"
    options.args << if ENV["BIG_SCREEN_SIZE"].present?
                      "--window-size=1920,3000"
                    else
                      "--window-size=1920,1080"
                    end
    options.args << "--ignore-certificate-errors" if ENV["TEST_SSL"]
    options.add_preference("intl.accept_languages", "en-GB")

    options.args << "--user-data-dir=#{@chrome_tmp_dir}/user-data"
    options.args << "--disk-cache-dir=#{@chrome_tmp_dir}/cache-dir"
    options.args << "--disable-application-cache"
    options.args << "--media-cache-size=1"
    options.args << "--incognito"

    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 120
    client.open_timeout = 120

    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: options,
      http_client: client,
      clear_local_storage: true,
      clear_session_storage: true
    )
  end
end
