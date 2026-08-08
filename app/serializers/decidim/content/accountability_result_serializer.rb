# frozen_string_literal: true

module Decidim
  module Content
    class AccountabilityResultSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          reference: resource.try(:reference),
          category: uid(resource.try(:category)),
          scope: uid(Decidim::Scope.new(id: resource.try(:decidim_scope_id))),
          parent: uid(Decidim::Accountability::Result.new(id: resource.try(:parent_id))),
          title: normalize_translated_attribute(resource.title),
          description: normalize_translated_attribute(resource.description),
          start_date: resource.try(:start_date),
          end_date: resource.try(:end_date),
          status: uid(Decidim::Accountability::Status.new(id: resource.try(:decidim_accountability_status_id))),
          progress: resource.try(:progress),
          timeline: timeline_entries,
          children_count: resource.try(:children_count),
          external_id: resource.try(:external_id),
          comment_count: resource.try(:comment_count),
          linked_proposals: resource.linked_resources(:proposals, "included_proposals").map { |proposal| uid(Decidim::Proposals::Proposal.new(id: proposal.id)) },
          linked_projects: resource.linked_resources(:projects, "included_projects").map { |project| uid(Decidim::Budgets::Project.new(id: project.id)) },
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          component: uid(resource.try(:component)),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        }
      end

      def timeline_entries
        resource.timeline_entries.collect do |entry|
          {
            date: entry.try(:date),
            title: normalize_translated_attribute(entry.try(:title)),
            description: normalize_translated_attribute(entry.try(:description))
            # created_at: entry.try(:created_at),
            # updated_at: entry.try(:updated_at)
          }
        end
      end
    end
  end
end
