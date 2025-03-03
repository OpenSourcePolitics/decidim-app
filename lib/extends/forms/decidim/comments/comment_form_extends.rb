# frozen_string_literal: true

require "active_support/concern"

module CommentFormExtends
  extend ActiveSupport::Concern

  included do
    attribute :current_component, Decidim::Component
  end
end

Decidim::Comments::CommentForm.include(CommentFormExtends)
