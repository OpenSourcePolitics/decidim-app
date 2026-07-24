# frozen_string_literal: true

module Decidim
  module Initiatives
    class NotifyProgressInitiatives < ApplicationJob
      queue_as :initiatives

      def perform
        system "rake decidim_initiatives:notify_progress"
      end
    end
  end
end
