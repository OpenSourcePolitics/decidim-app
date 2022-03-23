# frozen_string_literal: true

source "https://rubygems.org"

DECIDIM_VERSION = "release/0.25-stable"

ruby RUBY_VERSION

gem "decidim", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION

gem "acts_as_textcaptcha", "~> 4.5.1"
gem "bootsnap", "~> 1.4"
gem "decidim-decidim_awesome"
gem "omniauth-publik", git: "https://github.com/OpenSourcePolitics/omniauth-publik", branch: "v0.0.9"
gem "decidim-phone_authorization_handler", git: "https://github.com/OpenSourcePolitics/decidim-module_phone_authorization_handler", branch: "bump/0.25-stable"
gem "decidim-question_captcha", git: "https://github.com/OpenSourcePolitics/decidim-module-question_captcha.git"
gem "decidim-spam_detection", git: "https://github.com/OpenSourcePolitics/decidim-spam_detection.git"
gem "decidim-term_customizer", git: "https://github.com/mainio/decidim-module-term_customizer.git"

gem "dotenv-rails"

gem "foundation_rails_helper", git: "https://github.com/sgruhier/foundation_rails_helper.git"
gem "puma", "~> 5.5.1"

gem "faker", "~> 2.14"

gem "ruby-progressbar"

gem "letter_opener_web", "~> 1.3"

gem "activejob-uniqueness", require: "active_job/uniqueness/sidekiq_patch"
gem "fog-aws"
gem "sys-filesystem"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION
end

group :development do
  gem "listen", "~> 3.1"
  gem "rubocop-faker"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
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
