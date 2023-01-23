# frozen_string_literal: true

module Decidim
  module Forms
    module StepNavigationCellExtends
      def errors
        options[:errors]
      end
    end
  end
end

Decidim::Forms::StepNavigationCell.class_eval do
  prepend(Decidim::Forms::StepNavigationCellExtends)
end
