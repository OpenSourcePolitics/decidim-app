# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION
DECIDIM_TAG = "v0.29.3"

gem "decidim", github: "decidim/decidim", tag: DECIDIM_TAG
gem "decidim-conferences", github: "decidim/decidim", tag: DECIDIM_TAG
gem "decidim-initiatives", github: "decidim/decidim", tag: DECIDIM_TAG
gem "decidim-templates", github: "decidim/decidim", tag: DECIDIM_TAG

gem "bootsnap", "~> 1.4", require: false
gem "puma", ">= 6.3.1"

gem "activerecord-postgis-adapter", "~> 8.0", ">= 8.0.3"
gem "aws-sdk-s3", require: false
gem "dalli"
gem "deface"
gem "dotenv-rails", "~> 2.7"
gem "faker", "~> 3.2"
gem "letter_opener_web", "~> 2.0"
gem "rack-attack", "~> 6.7"
gem "rgeo"
gem "rgeo-activerecord"

# gems updated with bundle-audit
gem "actionpack", "~> 7.0.8.7"
gem "graphql", "~> 2.2.17"
gem "net-imap", ">= 0.5.6"
gem "nokogiri", ">= 1.18.4"
gem "rack", "~> 2.2.14"
gem "uri", ">= 1.0.3"

# omniauth
gem "omniauth-publik", git: "https://github.com/OpenSourcePolitics/omniauth-publik.git", branch: "feat/update_to_0.29"

# Load Budgets Booth to avoid errors
gem "decidim-budgets_booth", github: "OpenSourcePolitics/decidim-module-ptp", branch: "bump/0.29-budgets_booth"

# External Decidim gems
gem "decidim-additional_authorization_handler", git: "https://github.com/OpenSourcePolitics/decidim-module-additional_authorization_handler.git"
gem "decidim-admin_multi_factor", git: "https://github.com/OpenSourcePolitics/decidim-module-admin_multi_factor.git", branch: "rc-0.29"
gem "decidim-cleaner", git: "https://github.com/OpenSourcePolitics/decidim-module-cleaner.git", branch: "bump/0.29"
gem "decidim-decidim_awesome", git: "https://github.com/decidim-ice/decidim-module-decidim_awesome.git"
gem "decidim-emitter", git: "https://github.com/OpenSourcePolitics/decidim-module-emitter.git", branch: "bump/0.29"
gem "decidim-extra_user_fields", git: "https://github.com/OpenSourcePolitics/decidim-module-extra_user_fields.git", branch: "bump/0.29"
gem "decidim-guest_meeting_registration", git: "https://github.com/OpenSourcePolitics/guest-meeting-registration.git", branch: "bump/module_to_0.29"
gem "decidim-survey_multiple_answers", git: "https://github.com/OpenSourcePolitics/decidim-module-survey_multiple_answers.git", branch: "bump/0.29"
gem "decidim-term_customizer", git: "https://github.com/OpenSourcePolitics/decidim-module-term_customizer.git", branch: "backport/fix_database_not_available"

gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection", "~> 1.0"

group :development, :test do
  gem "brakeman", "~> 6.1"
  gem "bundler-audit", require: false
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", github: "decidim/decidim", tag: DECIDIM_TAG
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
