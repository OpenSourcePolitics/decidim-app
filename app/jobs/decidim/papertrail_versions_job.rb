# frozen_string_literal: true

module Decidim
  class PapertrailVersionsJob < ApplicationJob
    queue_as :default

    include Decidim::Logging

    def perform(expiration = 6.months.ago)
      log! "Cleaning versions in database..."
      elements = ["Decidim::UserBaseEntity", "Decidim::Comments::Comment", "Decidim::Attachment", "Decidim::Blogs::Post"]
      log! "Cleaning item_types : #{elements.join(", ")}"

      total = 0
      PaperTrail::Version.where(item_type: elements).where("created_at <= ?", expiration).in_batches do |versions|
        total += versions.size
        versions.destroy_all
      end

      log! "#{total} users have been removed"
    end
  end
end
