# frozen_string_literal: true

module Decidim
  module Budgets
    class PendingOrderEvent < Decidim::Events::SimpleEvent
      def resource_text
        translated_attribute(resource.title)
      end
    end
  end
end
