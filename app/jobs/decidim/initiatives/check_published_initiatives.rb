# frozen_string_literal: true

module Decidim
  module Initiatives
    class CheckPublishedInitiatives < ApplicationJob
      queue_as :initiatives

      def perform
        system "rake decidim_initiatives:check_published"
      end
    end
  end
end
