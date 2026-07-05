# frozen_string_literal: true

module Decidim
  module Content
    class BudgetOrderSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          user: uid(Decidim::User.new(id: resource.try(:decidim_user_id))),
          status: resource.try(:checked_out_at).present? ? "finished" : "pending",
          # budget: uid(Decidim::Budgets::Budget.new(id: resource.try(:decidim_budget_id))),
          projects: resource.try(:line_items).map { |line| uid(Decidim::Budgets::Project.new(id: line.try(:decidim_project_id))) },
          # total_budget: resource.try(:total_budget),
          # total_projects: resource.try(:total_projects),
          checked_out_at: resource.try(:checked_out_at),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at)
        }
      end
    end
  end
end
