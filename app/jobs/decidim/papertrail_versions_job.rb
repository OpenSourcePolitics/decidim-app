# frozen_string_literal: true

module Decidim
  class PapertrailVersionsJob < ApplicationJob
    queue_as :default

    include Decidim::Logging

    def perform(ret = nil)
      ret = retention(ret)

      log! "Cleaning versions in database..."
      log! "Cleaning item_types : #{item_types.join(", ")}"

      total = 0
      PaperTrail::Version.where(item_type: item_types).where("created_at <= ?", ret).in_batches(of: 5000) do |versions|
        total += versions.size
        versions.destroy_all
      end

      log! "#{total} versions have been removed"
    end

    private

    def retention(ret)
      return ret if ret.present? && ret.is_a?(Time)

      ret = Rails.application.secrets.dig(:decidim, :database, :versions, :clean, :retention)
      ret.months.ago
    end

    # Exhaustive list of item_types to remove from versions table
    def item_types
      @item_types ||= %w(
        Decidim::Accountability::TimelineEntry
        Decidim::Accountability::Result
        Decidim::Attachment
        Decidim::AttachmentCollection
        Decidim::Blogs::Post
        Decidim::Budgets::Project
        Decidim::Comments::Comment
        Decidim::Conferences::MediaLink
        Decidim::Conferences::Partner
        Decidim::Debates::Debate
        Decidim::Categorization
        Decidim::Categorization
        Decidim::Forms::Questionnaire
        Decidim::UserBaseEntity
      )
    end
  end
end
