# frozen_string_literal: true

module Decidim
  class PapertrailVersionsJob < ApplicationJob
    queue_as :default

    include Decidim::Logging

    def perform(expiration = 6.months.ago)
      log! "Cleaning versions in database..."
      elements = [
                  "Decidim::Accountability::TimelineEntry",
                  "Decidim::Accountability::Result",
                  "Decidim::Attachment",
                  "Decidim::AttachmentCollection",
                  "Decidim::Blogs::Post",
                  "Decidim::Budgets::Project",
                  "Decidim::Comments::Comment",
                  "Decidim::Conferences::MediaLink",
                  "Decidim::Conferences::Partner",
                  "Decidim::Debates::Debate",
                  "Decidim::Categorization",
                  "Decidim::Categorization",
                  "Decidim::Forms::Questionnaire",
                  "Decidim::UserBaseEntity",
      ]
      log! "Cleaning item_types : #{elements.join(", ")}"

      total = 0
      PaperTrail::Version.where(item_type: elements).where("created_at <= ?", expiration).in_batches do |versions|
        total += versions.size
        versions.destroy_all
      end

      log! "#{total} versions have been removed"
    end
  end
end
