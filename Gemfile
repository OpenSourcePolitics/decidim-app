# frozen_string_literal: true

source "https://rubygems.org"

DECIDIM_VERSION = "release/0.26-stable"

ruby RUBY_VERSION

gem "decidim", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION
gem "decidim-conferences", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION

# gem "acts_as_textcaptcha", "~> 4.5.1"
gem "decidim-decidim_awesome"
gem "decidim-friendly_signup", git: "https://github.com/OpenSourcePolitics/decidim-module-friendly_signup.git"
gem "decidim-homepage_interactive_map", git: "https://github.com/OpenSourcePolitics/decidim-module-homepage_interactive_map.git", branch: DECIDIM_VERSION
gem "decidim-ludens", git: "https://github.com/OpenSourcePolitics/decidim-ludens.git"
gem "decidim-phone_authorization_handler", git: "https://github.com/OpenSourcePolitics/decidim-module_phone_authorization_handler", branch: DECIDIM_VERSION
# gem "decidim-question_captcha", git: "https://github.com/OpenSourcePolitics/decidim-module-question_captcha.git", branch: DECIDIM_VERSION
gem "decidim-spam_detection", git: "https://github.com/OpenSourcePolitics/decidim-spam_detection.git"
gem "decidim-templates"
gem "decidim-term_customizer", git: "https://github.com/mainio/decidim-module-term_customizer.git"
gem "omniauth-france_connect", git: "https://github.com/OpenSourcePolitics/omniauth-france_connect"
gem "omniauth-publik", git: "https://github.com/OpenSourcePolitics/omniauth-publik"

gem "dotenv-rails"

gem "bootsnap", "~> 1.4"
gem "foundation_rails_helper", git: "https://github.com/sgruhier/foundation_rails_helper.git"

gem "puma", ">= 5.5.1"

gem "faker", "~> 2.14"

gem "activejob-uniqueness", require: "active_job/uniqueness/sidekiq_patch"
gem "aws-sdk-s3", require: false
gem "fog-aws"
gem "sys-filesystem"

gem "omniauth-rails_csrf_protection", "~> 1.0"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "brakeman", "~> 5.1"
  gem "decidim-dev", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION
end

group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "rubocop-faker"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "4.0.4"
end

group :production do
  gem "dalli"
  gem "lograge"
  gem "newrelic_rpm"
  gem "passenger"
  gem "sendgrid-ruby"
  gem "sentry-rails"
  gem "sentry-ruby"
  gem "sentry-sidekiq"
  gem "sidekiq"
  gem "sidekiq-scheduler"
end
gem "nokogiri", "1.13.4"
