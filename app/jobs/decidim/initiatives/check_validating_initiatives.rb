# frozen_string_literal: true

module Decidim
  module Initiatives
    class CheckValidatingInitiatives < ApplicationJob
      queue_as :initiatives

      def perform
        system "rake decidim_initiatives:check_validating"
      end
    end
  end
end
