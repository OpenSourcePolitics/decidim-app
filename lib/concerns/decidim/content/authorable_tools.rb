# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module AuthorableTools
      extend ActiveSupport::Concern
      included do
        def identity(resource)
          resource.try(:user_group) || resource.try(:author)
        end

        def coauthors(resource)
          return [] unless resource.respond_to?(:coauthorships)

          resource.coauthorships.map { |c| identity(c) }
        end
      end
    end
  end
end
