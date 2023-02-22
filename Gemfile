# frozen_string_literal: true

source "https://rubygems.org"

DECIDIM_VERSION = "release/0.26-stable"

ruby RUBY_VERSION

gem "activejob-uniqueness", require: "active_job/uniqueness/sidekiq_patch"
gem "aws-sdk-s3", require: false
gem "bootsnap", "~> 1.4"
gem "decidim", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION
gem "decidim-conferences", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION
gem "decidim-decidim_awesome"
gem "decidim-friendly_signup", git: "https://github.com/OpenSourcePolitics/decidim-module-friendly_signup.git"
gem "decidim-homepage_interactive_map", git: "https://github.com/OpenSourcePolitics/decidim-module-homepage_interactive_map.git", branch: DECIDIM_VERSION
gem "decidim-ludens", git: "https://github.com/OpenSourcePolitics/decidim-ludens.git"
gem "decidim-phone_authorization_handler", git: "https://github.com/OpenSourcePolitics/decidim-module_phone_authorization_handler", branch: DECIDIM_VERSION
gem "decidim-spam_detection", git: "https://github.com/OpenSourcePolitics/decidim-spam_detection.git"
gem "decidim-templates"
gem "decidim-term_customizer", git: "https://github.com/mainio/decidim-module-term_customizer.git"
gem "dotenv-rails"
gem "faker", "~> 2.14"
gem "fog-aws"
gem "foundation_rails_helper", git: "https://github.com/sgruhier/foundation_rails_helper.git"
gem "letter_opener_web", "~> 1.3"
gem "nokogiri", "1.13.4"
gem "omniauth-france_connect", git: "https://github.com/OpenSourcePolitics/omniauth-france_connect"
gem "omniauth-publik", git: "https://github.com/OpenSourcePolitics/omniauth-publik"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "puma", ">= 5.5.1"
gem "rack-attack", "~> 6.6"
gem "sys-filesystem"

group :development, :test do
  gem "brakeman", "~> 5.1"
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION
  gem "parallel_tests"
end

group :development do
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
