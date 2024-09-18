# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim-system", github: 'decidim/decidim', tag: 'v0.29.0'
gem "decidim-admin", github: 'decidim/decidim', tag: 'v0.29.0'
gem "decidim-core", github: 'decidim/decidim', tag: 'v0.29.0'
gem "decidim-participatory_processes", github: 'decidim/decidim', tag: 'v0.29.0'
gem "decidim-verifications", github: 'decidim/decidim', tag: 'v0.29.0'
gem "decidim-comments", github: 'decidim/decidim', tag: 'v0.29.0'

gem "bootsnap", "~> 1.4"

gem "puma", ">= 6.3.1"

gem "spring"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", github: 'decidim/decidim', tag: 'v0.29.0'

  gem "brakeman", "~> 6.1"
  gem "parallel_tests", "~> 4.2"
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 4.2"
end

group :production do
end

group :development do
  # Profiling gems
  gem "bullet"
  gem "flamegraph"
  gem "memory_profiler"
  gem "rack-mini-profiler", require: false
  gem "stackprof"
end
