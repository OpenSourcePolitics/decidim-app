# frozen_string_literal: true

require "active_support/concern"

# Backport of decidim/decidim#17595 (not in the pinned 0.31 commit).
# The open data collection filters on `decidim_users.blocked_at`, but
# `blocking` is resolved through `decidim_users.block_id`. Users blocked by
# decidim-spam_detection 4.1.0 got a UserBlock without `block_id`, so
# `blocking` is nil and the whole OpenDataJob aborted.
# Remove once Gemfile.lock points to a decidim commit that includes #17595.
module OpenDataBlockedUserSerializerExtends
  extend ActiveSupport::Concern

  included do
    def serialize
      {
        user_id: resource.user.id,
        blocked_at: resource.user.blocked_at,
        about: resource.user.about,
        reasons: resource.reports.map(&:reason),
        details: resource.reports.map(&:details),
        block_reasons: blocking&.justification,
        blocking_user: blocking_user&.presenter&.name
      }
    end

    private

    def blocking = resource.blocking

    def blocking_user = blocking&.blocking_user
  end
end

Decidim::Exporters::OpenDataBlockedUserSerializer.include(OpenDataBlockedUserSerializerExtends)
