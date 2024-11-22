# frozen_string_literal: true

return if Rails.env.production?

require "decidim/spring"

Spring.watch(
  ".ruby-version",
  ".rbenv-vars",
  "tmp/restart.txt",
  "tmp/caching-dev.txt"
)
