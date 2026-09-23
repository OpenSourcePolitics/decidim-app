# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module DecidimAwesomeTools
      extend ActiveSupport::Concern
      included do
        def proposal_custom_fields?
          defined?(Decidim::DecidimAwesome) && Decidim::DecidimAwesome.enabled?(:proposal_custom_fields)
        end

        def proposal_private_custom_fields?
          defined?(Decidim::DecidimAwesome) && Decidim::DecidimAwesome.enabled?(:proposal_private_custom_fields)
        end
      end
    end
  end
end
