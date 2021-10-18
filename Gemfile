# frozen_string_literal: true

source "https://rubygems.org"

DECIDIM_VERSION = "release/0.24-stable"

ruby RUBY_VERSION

gem "decidim", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION

gem "decidim-anonymous_proposals", git: "https://github.com/PopulateTools/decidim-module-anonymous_proposals", branch: :main
gem "decidim-decidim_awesome", "~> 0.7.0"
gem "decidim-question_captcha", git: "https://github.com/OpenSourcePolitics/decidim-module-question_captcha.git", branch: "master"
gem "decidim-term_customizer", git: "https://github.com/mainio/decidim-module-term_customizer.git", branch: "master"
gem "decidim-url_aliases", git: "https://github.com/OpenSourcePolitics/decidim-urlaliases.git", branch: "master"

gem "bootsnap", "~> 1.4"

gem "dotenv-rails"

gem "puma", "~> 5.3.1"
gem "uglifier", "~> 4.1"

gem "faker", "~> 2.14"

gem "ruby-progressbar"

gem "letter_opener_web", "~> 1.3"

gem "sprockets", "~> 3.7"

gem "activejob-uniqueness", require: "active_job/uniqueness/sidekiq_patch"
gem "fog-aws"
gem "sys-filesystem"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", git: "https://github.com/decidim/decidim.git", branch: DECIDIM_VERSION
  # gem "decidim-dev", path: "../decidim"
end

group :development do
  gem "listen", "~> 3.1"
  gem "rubocop-faker"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end

group :production do
  # gem "rubocop-rails"
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
