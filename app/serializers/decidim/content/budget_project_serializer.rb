# frozen_string_literal: true

module Decidim
  module Content
    class BudgetProjectSerializer < Decidim::Exporters::Serializer
      include Decidim::Content::SerializerTools

      def serialize
        {
          uid: uid(resource),
          reference: resource.try(:reference),
          title: normalize_translated_attribute(resource.title),
          description: normalize_translated_attribute(resource.description),
          budget_amount: resource.try(:budget_amount),
          # confirmed_votes: resource.try(:confirmed_orders_count),
          category: uid(resource.try(:category)),
          scope: uid(Decidim::Scope.new(id: resource.try(:decidim_scope_id))),
          address: resource.try(:address),
          latitude: resource.try(:latitude),
          longitude: resource.try(:longitude),
          comments_count: resource.try(:comments_count),
          follows_count: resource.try(:follows_count),
          created_at: resource.try(:created_at),
          updated_at: resource.try(:updated_at),
          selected_at: resource.try(:selected_at),
          budget: uid(resource.try(:budget)),
          component: uid(resource.try(:component)),
          url: Decidim::ResourceLocatorPresenter.new([resource.try(:budget), resource]).url
        }
      end
    end
  end
end
