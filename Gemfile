# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", git: "https://github.com/decidim/decidim.git", branch: "0.21-stable"
# gem "decidim", path: "../decidim"
# gem "decidim-map", path: "../decidim-map"

# gem "decidim-conferences", git: "https://github.com/decidim/decidim.git", branch: "0.21-stable"
# gem "decidim-consultations", git: "https://github.com/decidim/decidim.git", branch: "0.21-stable"
# gem "decidim-initiatives", git: "https://github.com/decidim/decidim.git", branch: "0.21-stable"

# gem "decidim-conferences", path: "../decidim"
# gem "decidim-consultations", path: "../decidim"
# gem "decidim-initiatives", path: "../decidim"

gem "decidim-calendar", git: "https://github.com/alabs/decidim-module-calendar"
#gem "decidim-cookies", git: "https://github.com/OpenSourcePolitics/decidim-module_cookies", branch: "feature/orejime"
#gem "decidim-combined_budgeting", git: "https://github.com/mainio/decidim-module-combined_budgeting"
gem "decidim-decidim_awesome", git: "https://github.com/Platoniq/decidim-module-decidim_awesome"
gem "decidim-comparative_stats", git: "https://github.com/Platoniq/decidim-module-comparative_stats"
gem "decidim-direct_verifications", git: "https://github.com/Platoniq/decidim-verifications-direct_verifications"
#gem "decidim-homepage_interactive_map", git: "https://github.com/OpenSourcePolitics/decidim-module-homepage_interactive_map.git"
#gem "decidim-initiatives_no_signature_allowed", git: "https://github.com/OpenSourcePolitics/decidim-module-initiatives_nosignature_allowed.git"
gem "decidim-navigation_maps", git: "https://github.com/Platoniq/decidim-module-navigation_maps"


gem "decidim-term_customizer", git: "https://github.com/OpenSourcePolitics/decidim-module-term_customizer.git", branch: "0.dev"

gem "bootsnap", "~> 1.3"

gem "puma", "~> 4.3"
gem "uglifier", "~> 4.1"

gem "faker", "~> 1.8"

gem "ruby-progressbar"
gem "sentry-raven"

gem "letter_opener_web", "~> 1.3"

gem "sprockets", "~> 3.7"

group :development, :test do
  gem "dotenv-rails"
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", git: "https://github.com/decidim/decidim.git", branch: "0.21-stable"
  # gem "decidim-dev", path: "../decidim"
end

group :development do
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end

group :production do
  # gem "rubocop-rails"
  gem "passenger"
  gem "fog-aws"
  gem "dalli"
  gem "sendgrid-ruby"
  gem "newrelic_rpm"
  gem "lograge"
  gem "sidekiq"
  gem "sidekiq-scheduler"
end
