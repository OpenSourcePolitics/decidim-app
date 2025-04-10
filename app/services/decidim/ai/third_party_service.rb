# frozen_string_literal: true

module Decidim
  module Ai
    class ThirdPartyService < Decidim::Ai::SpamDetection::Service
      def classify(klass, text)
        text = formatter.cleanup(text)
        return if text.blank?

        @registry.each do |strategy|
          strategy.classify(klass, text)
        end
      end
    end
  end
end
