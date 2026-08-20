# frozen_string_literal: true

module Decidim
  module Content
    class BudgetSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          title: normalize_translated_attribute(resource.title),
          description: normalize_translated_attribute(resource.description),
          total_budget: resource.try(:total_budget),
          scope: uid(Decidim::Scope.new(id: resource.try(:decidim_scope_id))),
          category_budget_rules: resource.try(:category_budget_rules),
          weight: resource.try(:weight),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          component: uid(resource.try(:component)),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        }
      end
    end
  end
end
