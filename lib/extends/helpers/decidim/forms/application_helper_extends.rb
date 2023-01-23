# frozen_string_literal: true

module Decidim
  module Forms
    module ApplicationHelperExtends
      def invalid?(responses)
        responses.map { |response| response.errors.any? }.any?
      end
    end
  end
end

Decidim::Forms::ApplicationHelper.module_eval do
  prepend(Decidim::Forms::ApplicationHelperExtends)
end
