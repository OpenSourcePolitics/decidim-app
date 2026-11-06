# frozen_string_literal: true

require "active_support/concern"

# One queued OpenDataJob per (organization, resource).
# While an open data file doesn't exist yet, every click on its download link
# enqueues a new job. On large organizations each export holds the whole CSV
# (and zip) in memory, so concurrent duplicates got the sidekiq pod OOMKilled.
#
# until_executed: the lock is taken on enqueue and released after perform.
# lock_ttl: releases the lock if the process dies mid-export.
# on_conflict :log: a duplicate perform_later returns false instead of raising,
# so the controller still redirects with "not available yet".
#
# activejob-uniqueness is in the Gemfile :production group only, so `unique`
# exists in production; in development and test the job stays as decidim ships it.
module OpenDataJobExtends
  extend ActiveSupport::Concern

  included do
    unique :until_executed, lock_ttl: 1.hour, on_conflict: :log
  end
end

Decidim::OpenDataJob.include(OpenDataJobExtends) if Decidim::OpenDataJob.respond_to?(:unique)
