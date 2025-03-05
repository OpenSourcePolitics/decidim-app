# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", github: "decidim/decidim", tag: "v0.29.2"

gem "bootsnap", "~> 1.4", require: false
gem "puma", ">= 6.3.1"

gem "aws-sdk-s3", require: false
gem "dalli"
gem "deface"
gem "dotenv-rails", "~> 2.7"
gem "faker", "~> 3.2"
gem "letter_opener_web", "~> 2.0"
gem "rack-attack", "~> 6.7"

# External Decidim gems
gem "decidim-additional_authorization_handler", git: "https://github.com/OpenSourcePolitics/decidim-module-additional_authorization_handler.git"

group :development, :test do
  gem "brakeman", "~> 6.1"
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", github: "decidim/decidim", tag: "v0.29.2"
  gem "parallel_tests", "~> 4.2"
  gem "spring"
end

group :development do
  gem "bullet"
  gem "flamegraph"
  gem "listen", "~> 3.1"
  gem "memory_profiler"
  gem "rack-mini-profiler", require: false
  gem "stackprof"
  gem "web-console", "~> 4.2"
end

group :production do
  gem "activejob-uniqueness", require: "active_job/uniqueness/sidekiq_patch"
  gem "health_check", "~> 3.1"
  gem "lograge"
  gem "sidekiq", "~> 6.0"
  gem "sidekiq-scheduler", "~> 5.0"
end
