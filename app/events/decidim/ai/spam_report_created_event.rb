# frozen_string_literal: true

module Decidim
  module Ai
    class SpamReportCreatedEvent < Decidim::Events::SimpleEvent
      def email_intro
        "Spam report automatically created by the AI system."
      end
    end
  end
end

